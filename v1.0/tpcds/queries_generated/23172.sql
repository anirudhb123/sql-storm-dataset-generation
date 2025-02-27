
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 
           CASE 
               WHEN ca_state IS NULL THEN 'Unknown State'
               ELSE ca_state 
           END AS state_desc
    FROM customer_address
    WHERE ca_address_sk IS NOT NULL
      
    UNION ALL
      
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state,
           CASE 
               WHEN ca_state IS NULL THEN 'Unknown State'
               ELSE ca_state 
           END AS state_desc
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ah.ca_city IS NOT NULL
)
SELECT c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, 
       COUNT(CASE WHEN c.c_birth_month = d.d_moy THEN 1 END) AS birth_month_count,
       SUM(CASE 
               WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_net_profit 
               ELSE 0 
           END) AS total_net_profit,
       ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) as profit_rank
FROM customer c
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN address_hierarchy a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
  AND (cd.cd_purchase_estimate BETWEEN 100 AND 1000 OR cd.cd_credit_rating IS NULL)
  AND (EXISTS (SELECT 1 FROM store s WHERE s.s_country = a.ca_country AND s.s_city = a.ca_city))
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city
HAVING COUNT(ws.ws_order_number) > 0
  AND MAX(ws.ws_net_profit) IS NOT NULL
ORDER BY profit_rank
LIMIT 10;
