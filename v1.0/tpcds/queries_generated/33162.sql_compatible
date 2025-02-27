
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
),
high_value_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.total_orders,
        ci.total_spent,
        CASE 
            WHEN ci.total_spent > 1000 THEN 'High Value'
            WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_info ci
    WHERE
        ci.total_orders > 5
),
max_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_net_profit,
        sd.order_count,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS item_rank
    FROM 
        sales_data sd
)
SELECT 
    hvc.ca_city,
    hvc.ca_state,
    hvc.customer_value,
    MAX(ms.total_net_profit) AS max_item_profit,
    (SELECT COUNT(DISTINCT ws_item_sk) 
     FROM web_sales 
     WHERE ws_ship_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = hvc.c_customer_id)) AS distinct_items_purchased
FROM 
    high_value_customers hvc
JOIN 
    max_sales ms ON hvc.total_spent = ms.total_net_profit
WHERE 
    hvc.customer_value = 'High Value'
GROUP BY 
    hvc.ca_city, hvc.ca_state, hvc.customer_value
ORDER BY 
    hvc.ca_city, hvc.ca_state;
