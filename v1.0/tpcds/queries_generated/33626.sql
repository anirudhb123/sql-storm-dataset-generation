
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_buy_potential,
           CAST(1 AS INTEGER) AS level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year < 2000

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_buy_potential,
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk AND ch.level < 3
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT ca.city, ca.state, COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
       AVG(CASE WHEN ch.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_ratio,
       SUM(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_dep_count ELSE 0 END) AS married_dependents,
       SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit
FROM customer_hierarchy ch
JOIN customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
WHERE dd.d_year = 2023
GROUP BY ca.city, ca.state
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY customer_count DESC, city ASC
LIMIT 10;
