
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_birth_year,
           1 AS level
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_year,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)
SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(DATEDIFF(CURDATE(), c.c_birth_year)) AS avg_age,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
    STRING_AGG(DISTINCT cd.cd_gender) AS unique_genders,
    ROW_NUMBER() OVER (PARTITION BY ca.state ORDER BY COUNT(DISTINCT c.c_customer_id) DESC) AS state_rank
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS ws_net_profit
            FROM web_sales GROUP BY ws_bill_customer_sk) ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE c.c_birth_year < (YEAR(CURDATE()) - 18)
GROUP BY ca.city, ca.state
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY state_rank, total_net_profit DESC;
