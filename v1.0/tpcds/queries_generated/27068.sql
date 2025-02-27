
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws.ws_sales_price) AS median_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.ca_city,
    c.ca_state,
    c.ca_country,
    c.full_address,
    c.c_email_address,
    is.total_quantity_sold,
    is.total_sales_amount,
    is.median_sales_price
FROM 
    CustomerData c
LEFT JOIN 
    ItemSales is ON c.c_customer_sk = is.ws_item_sk
WHERE 
    c.cd_gender = 'F'
    AND c.cd_marital_status = 'M'
ORDER BY 
    is.total_sales_amount DESC
LIMIT 100;
