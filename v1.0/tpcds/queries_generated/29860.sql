
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ca.city,
        ca.state,
        LOWER(REPLACE(REPLACE(c.c_email_address, '@', ' AT '), '.', ' DOT ')) AS obfuscated_email,
        cd.education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_sales AS (
    SELECT 
        d.d_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date_sk
),
combined AS (
    SELECT 
        cd.full_name,
        cd.gender,
        cd.city,
        cd.state,
        cd.obfuscated_email,
        cd.education_status,
        ds.total_sales,
        ds.order_count
    FROM 
        customer_data cd
    LEFT JOIN 
        date_sales ds ON ds.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    gender,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(order_count) AS total_orders,
    COUNT(DISTINCT obfuscated_email) AS unique_emails
FROM 
    combined
GROUP BY 
    gender
ORDER BY 
    customer_count DESC;
