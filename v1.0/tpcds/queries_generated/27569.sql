
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM customer_info ci
    LEFT JOIN sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales >= 10000 THEN 'Gold'
        WHEN total_sales >= 5000 THEN 'Silver'
        ELSE 'Bronze' 
    END AS customer_tier
FROM top_customers
ORDER BY total_sales DESC
LIMIT 10;
