
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_age_group,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), FilteredSales AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discounts,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_customer_sk
)

SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.ca_country,
    COALESCE(fs.total_sales, 0) AS total_sales,
    COALESCE(fs.order_count, 0) AS order_count,
    COALESCE(fs.total_discounts, 0) AS total_discounts,
    COALESCE(fs.total_tax, 0) AS total_tax
FROM 
    CustomerInfo ci
LEFT JOIN 
    FilteredSales fs ON ci.c_customer_sk = fs.ws_customer_sk
WHERE 
    ci.cd_purchase_estimate >= 1000
ORDER BY 
    total_sales DESC
FETCH FIRST 50 ROWS ONLY;
