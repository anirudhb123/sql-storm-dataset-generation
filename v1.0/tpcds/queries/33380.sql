
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           1 AS level, CAST(c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM customer c
    WHERE c.c_current_addr_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_addr_sk,
           ch.level + 1, CAST(ch.full_name || ' -> ' || c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100))
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
)

SELECT ca.ca_city, 
       COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
       SUM(ws.ws_net_profit) AS total_net_profit,
       AVG(ws.ws_list_price) AS avg_list_price,
       MAX(ws.ws_ext_sales_price) AS max_sales_price,
       MIN(ws.ws_net_paid) AS min_net_paid
FROM CustomerHierarchy ch
JOIN customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_city IS NOT NULL 
  AND ws.ws_sold_date_sk IN (SELECT d_date_sk 
                              FROM date_dim 
                              WHERE d_year = 2023)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT ch.c_customer_sk) > 10
ORDER BY total_net_profit DESC
LIMIT 10;
