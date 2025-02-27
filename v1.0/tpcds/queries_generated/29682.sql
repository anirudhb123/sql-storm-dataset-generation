
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS average_spent,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ci.order_count,
        ci.total_spent,
        ci.average_spent
    FROM ranked_sales ci
    JOIN customer c ON ci.customer_id = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    c_city,
    c_state,
    cd_gender,
    cd_marital_status,
    order_count,
    total_spent,
    average_spent
FROM customer_info
WHERE rank <= 10
ORDER BY total_spent DESC;
