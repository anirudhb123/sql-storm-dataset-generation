
WITH processed_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@example.com', '@tpcds.com') AS modified_email,
        TRIM(BOTH ' ' FROM CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS trimmed_salutation_name,
        LOWER(c.c_city) AS lower_city_name,
        LENGTH(c.c_email_address) AS email_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20000101 AND 20231231
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    pc.full_name,
    pc.modified_email,
    pc.trimmed_salutation_name,
    pc.lower_city_name,
    ss.total_profit,
    ss.total_orders,
    ss.avg_order_value,
    pc.email_length
FROM 
    processed_customers pc
LEFT JOIN 
    sales_summary ss ON pc.c_customer_sk = ss.customer_sk
ORDER BY 
    ss.total_profit DESC
LIMIT 100;
