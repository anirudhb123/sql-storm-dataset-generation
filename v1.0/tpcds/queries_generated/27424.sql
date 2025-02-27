
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
),
customer_details AS (
    SELECT 
        c_customer_id,
        full_name,
        ca_city,
        ca_state,
        cd_gender
    FROM ranked_customers
    WHERE rn <= 5
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        ss.total_spent,
        ss.total_orders
    FROM customer_details cd
    JOIN sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
    WHERE ss.total_spent > 1000
)
SELECT 
    hvc.full_name,
    hvc.ca_city,
    hvc.ca_state,
    hvc.cd_gender,
    hvc.total_spent,
    hvc.total_orders
FROM high_value_customers hvc
ORDER BY hvc.total_spent DESC, hvc.total_orders DESC;
