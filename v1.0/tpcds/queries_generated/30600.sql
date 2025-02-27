
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 
           ca.ca_city, ca.ca_state, 1 AS level
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL AND c.c_birth_year < 1980
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 
           ca.ca_city, ca.ca_state, ch.level + 1
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)
SELECT
    ch.c_customer_sk,
    ch.c_first_name || ' ' || ch.c_last_name AS full_name,
    ch.ca_city,
    ch.ca_state,
    COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS total_orders,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
    SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0) AS avg_order_value,
    CASE 
        WHEN COALESCE(SUM(ws.ws_ext_sales_price), 0) = 0 THEN 'No Sales'
        WHEN COALESCE(SUM(ws.ws_ext_sales_price), 0) BETWEEN 0 AND 100 THEN 'Low Sales'
        WHEN COALESCE(SUM(ws.ws_ext_sales_price), 0) BETWEEN 101 AND 500 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM customer_hierarchy ch
LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.ca_city, ch.ca_state
ORDER BY total_sales DESC
LIMIT 10;
