
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_id, s_store_name, s_manager, s_number_employees, 1 AS level
    FROM store
    WHERE s_store_id IS NOT NULL
    UNION ALL
    SELECT st.s_store_sk, st.s_store_id, st.s_store_name, st.s_manager, st.s_number_employees, sh.level + 1
    FROM store st
    JOIN sales_hierarchy sh ON st.s_manager = sh.s_store_name
),
total_sales AS (
    SELECT ss_store_sk, SUM(ss_net_paid) AS total_sales_amount
    FROM store_sales
    GROUP BY ss_store_sk
),
customer_metrics AS (
    SELECT c.c_customer_sk, 
           COUNT(DISTINCT CASE WHEN w.ws_ship_mode_sk IS NOT NULL THEN w.ws_order_number END) AS total_web_orders,
           COUNT(DISTINCT CASE WHEN c.c_birth_year IS NOT NULL AND c.c_birth_year < 1990 THEN c.c_customer_sk END) AS senior_customers
    FROM customer c
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT ca.ca_city, 
       ca.ca_state,
       COALESCE(SUM(ts.total_sales_amount), 0) AS total_sales,
       AVG(cm.total_web_orders) AS avg_web_orders,
       COUNT(DISTINCT cm.c_customer_sk) AS unique_customers,
       MAX(CASE WHEN cm.senior_customers > 0 THEN 'Yes' ELSE 'No' END) AS had_seniors,
       ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(SUM(ts.total_sales_amount), 0) DESC) AS rank_within_state
FROM customer_address ca
LEFT JOIN total_sales ts ON ca.ca_address_sk = ts.ss_store_sk
LEFT JOIN customer_metrics cm ON cm.c_customer_sk = ca.ca_address_sk
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT cm.c_customer_sk) > 5
ORDER BY total_sales DESC, ca.ca_city;
