
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca ca_state,
        ca.ca_country,
        ca.ca_zip,
        SUBSTRING(c.c_email_address, CHARINDEX('@', c.c_email_address) + 1, LEN(c.c_email_address)) AS email_domain
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
RankedCustomers AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.ca_zip,
        si.total_sales,
        si.order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_ship_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.ca_city,
    rc.ca_state,
    rc.ca_country,
    rc.ca_zip,
    rc.total_sales,
    rc.order_count,
    rc.sales_rank
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 100
ORDER BY 
    rc.sales_rank;
