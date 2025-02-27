
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_gender, 
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year >= 1980

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.cd_marital_status, ch.cd_gender, 
           level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_customer_sk = ch.c_customer_sk + 1
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT
    ca.ca_city,
    COUNT(DISTINCT ch.c_customer_sk) AS total_customers,
    AVG(ch.level) AS average_level,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    MAX(ch.level) AS max_level,
    MIN(ch.level) AS min_level
FROM customer_hierarchy ch
JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_country IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT ch.c_customer_sk) > 5
  AND AVG(ch.level) > 1
ORDER BY total_customers DESC
LIMIT 10;
