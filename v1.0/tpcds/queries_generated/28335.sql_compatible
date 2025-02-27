
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
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS number_of_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
report AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ss.total_spent,
        ss.number_of_orders
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_id = ss.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(number_of_orders, 0) AS number_of_orders,
    CASE 
        WHEN total_spent IS NULL THEN 'New Customer'
        WHEN total_spent > 1000 THEN 'Premium Customer'
        ELSE 'Standard Customer'
    END AS customer_type
FROM report
ORDER BY total_spent DESC;
