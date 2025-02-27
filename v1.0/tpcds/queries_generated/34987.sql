
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    MAX(ws.ws_net_paid) AS max_net_paid,
    MIN(ws.ws_net_paid) AS min_net_paid,
    STRING_AGG(DISTINCT c.cd_gender) AS genders_involved
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
JOIN date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
WHERE dd.d_year >= 2021 
  AND ca.ca_country IS NOT NULL 
  AND (c.c_birth_year BETWEEN 1980 AND 1990 OR c.c_birth_country IS NOT NULL)
GROUP BY ca.ca_city, ca.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_sales DESC, ca.ca_city ASC
LIMIT 100;
