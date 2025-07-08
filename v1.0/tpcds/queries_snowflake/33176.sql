
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender, 1 AS hierarchy_level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year >= 1980
    UNION ALL
    SELECT c2.c_customer_sk, c2.c_first_name, c2.c_last_name, cd2.cd_marital_status, cd2.cd_gender, ch.hierarchy_level + 1
    FROM customer c2
    JOIN CustomerHierarchy ch ON c2.c_current_cdemo_sk = ch.c_customer_sk
    JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
)
SELECT ca.ca_city, 
       SUM(ws.ws_net_profit) AS total_net_profit, 
       COUNT(DISTINCT c.c_customer_sk) AS customer_count,
       AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
       CASE 
           WHEN COUNT(DISTINCT c.c_customer_sk) > 0 THEN SUM(ws.ws_net_profit) / COUNT(DISTINCT c.c_customer_sk) 
           ELSE 0 
       END AS avg_profit_per_customer
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
LEFT JOIN Date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE (dd.d_year = 2023 OR dd.d_year = 2022)
AND (c.c_customer_sk IN (SELECT c_customer_sk FROM CustomerHierarchy WHERE hierarchy_level = 2))
AND ws.ws_net_paid_inc_tax IS NOT NULL
GROUP BY ca.ca_city
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY avg_net_paid DESC
LIMIT 10;
