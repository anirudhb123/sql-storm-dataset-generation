
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_id, s_store_name, s_number_employees,
           s_floor_space, s_city, s_state, s_country, 
           CAST(s_store_name AS VARCHAR(100)) AS hierarchy_path,
           1 AS level
    FROM store
    WHERE s_state = 'CA'

    UNION ALL

    SELECT s2.s_store_sk, s2.s_store_id, s2.s_store_name, s2.s_number_employees,
           s2.s_floor_space, s2.s_city, s2.s_state, s2.s_country, 
           CONCAT(sh.hierarchy_path, ' -> ', s2.s_store_name) AS hierarchy_path,
           sh.level + 1
    FROM store s2
    JOIN sales_hierarchy sh ON s2.s_market_id = sh.s_store_sk 
    WHERE sh.level < 3
),
total_sales AS (
    SELECT ws.store_sk, SUM(ws.net_paid) AS total_net_sales
    FROM web_sales ws
    JOIN sales_hierarchy sh ON ws.ws_store_sk = sh.s_store_sk
    GROUP BY ws.store_sk
),
avg_sales AS (
    SELECT AVG(total_net_sales) AS average_sales
    FROM total_sales
),
customer_counts AS (
    SELECT ca.cc_call_center_id, COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM call_center ca
    LEFT JOIN customer c ON ca.cc_call_center_sk = c.c_current_hdemo_sk
    GROUP BY ca.cc_call_center_id
)
SELECT sh.hierarchy_path,
       sh.s_store_name,
       sh.s_number_employees,
       sh.s_floor_space,
       tc.total_customers,
       ts.total_net_sales,
       ROUND((ts.total_net_sales - ac.average_sales) / ac.average_sales * 100, 2) AS sales_performance
FROM sales_hierarchy sh
LEFT JOIN total_sales ts ON sh.s_store_sk = ts.store_sk
JOIN customer_counts tc ON tc.cc_call_center_id = 'CC001'
CROSS JOIN avg_sales ac
WHERE ts.total_net_sales > 0
ORDER BY sales_performance DESC;
