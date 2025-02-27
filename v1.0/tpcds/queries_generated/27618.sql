
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        REGEXP_REPLACE(ca_zip, '[^0-9]', '') AS clean_zip,
        ca_city,
        ca_state
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
processed_customers AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_email_address,
        cd_demo_sk,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 180 FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    pca.full_address,
    pc.full_name,
    pc.cd_gender,
    ss.total_orders,
    ss.total_sales,
    ss.avg_sales_price
FROM 
    processed_addresses pca
JOIN 
    processed_customers pc ON pc.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_bill_customer_sk IS NOT NULL)
LEFT JOIN 
    sales_summary ss ON ss.ws_bill_customer_sk = pc.c_customer_sk
WHERE 
    pca.clean_zip LIKE '12345%' 
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
