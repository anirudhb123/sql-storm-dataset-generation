
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cad.ca_city,
        cad.ca_state,
        cad.ca_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.cd_gender,
        ci.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count
FROM 
    CustomerSales
WHERE 
    (cd_gender = 'F' AND order_count > 5)
    OR (cd_gender = 'M' AND total_sales > 1000)
ORDER BY 
    total_sales DESC, order_count DESC;
