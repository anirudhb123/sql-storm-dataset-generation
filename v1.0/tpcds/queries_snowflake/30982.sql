
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
)

SELECT ca.ca_city,
       COUNT(DISTINCT c.c_customer_id) AS total_customers,
       SUM(ws.ws_net_paid) AS total_sales,
       COUNT(sr.sr_ticket_number) AS total_returns,
       AVG(ws.ws_net_paid_inc_tax) AS avg_sales,
       DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE ca.ca_state = 'CA'
  AND c.c_first_shipto_date_sk IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM customer_hierarchy ch
      WHERE ch.c_customer_sk = c.c_customer_sk
      AND ch.level <= 2
  )
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY total_sales DESC
LIMIT 10;
