
WITH RECURSIVE employee_hierarchy AS (
    SELECT cc_manager, cc_name, 0 AS level
    FROM call_center
    WHERE cc_name IS NOT NULL
    UNION ALL
    SELECT c.cc_manager, c.cc_name, eh.level + 1
    FROM call_center c
    JOIN employee_hierarchy eh ON c.cc_manager = eh.cc_name
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_profiles AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws_net_profit) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cp.total_spent,
        cp.order_count,
        CASE 
            WHEN cp.total_spent > 1000 THEN 'High'
            WHEN cp.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS value_segment
    FROM customer_profiles cp
    JOIN customer c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    eh.cc_name AS manager_name,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(hvc.total_spent) AS total_revenue,
    AVG(hvc.order_count) AS avg_orders,
    STRING_AGG(DISTINCT hvc.value_segment, ', ') AS customer_segments
FROM employee_hierarchy eh
LEFT JOIN high_value_customers hvc ON eh.cc_name = hvc.c_customer_id
LEFT JOIN customer c ON hvc.c_customer_id = c.c_customer_id
GROUP BY eh.cc_name
HAVING COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY total_revenue DESC;
