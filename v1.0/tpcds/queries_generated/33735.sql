
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           0 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
)
SELECT ca.ca_country, 
       COUNT(DISTINCT c.c_customer_id) AS customer_count,
       SUM(NULLIF(ws.ws_net_profit, 0)) as total_profit,
       AVG(ws.ws_sales_price) AS average_sales_price,
       MAX(ws.ws_net_paid_inc_tax) AS max_paid_inc_tax,
       CASE 
           WHEN AVG(cd.cd_purchase_estimate) > 1000 THEN 'High Value'
           ELSE 'Low Value'
       END AS customer_category
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN inventory i ON ws.ws_item_sk = i.inv_item_sk 
WHERE (ca.ca_country IS NOT NULL OR ca.ca_country != 'USA')
  AND EXISTS (
       SELECT 1
       FROM customer_hierarchy ch
       WHERE ch.c_customer_sk = c.c_customer_sk
       AND ch.level < 3
  )
GROUP BY ca.ca_country
HAVING SUM(ws.ws_quantity) > 50
ORDER BY customer_count DESC
LIMIT 10;
