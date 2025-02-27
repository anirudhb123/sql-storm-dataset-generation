
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk 
    WHERE ch.level < 5
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT ch.c_customer_sk) AS unique_customers,
    STRING_AGG(DISTINCT CONCAT(ch.c_first_name, ' ', ch.c_last_name)) AS customer_names,
    SUM(COALESCE(ss.net_profit, 0)) AS total_net_profit,
    AVG(CASE WHEN ch.level > 1 THEN ss.net_profit END) AS avg_profit_above_first_level,
    SUM(CASE WHEN sm.sm_type = 'Express' THEN ss.ss_sales_price END) AS express_sales,
    COUNT(CASE WHEN ss.ss_customer_sk IS NULL THEN 1 END) AS null_customer_sales,
    MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_purchase_estimate END) AS max_female_est,
    MIN(CASE WHEN cd.cd_marital_status IS NULL THEN cd.cd_dep_count ELSE 0 END) AS min_dependent_count,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(DISTINCT ch.c_customer_sk) DESC) AS city_rank
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
LEFT JOIN store_sales ss ON ss.ss_customer_sk = ch.c_customer_sk
LEFT JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN ship_mode sm ON ss.ss_sales_price > 100 AND sm.sm_ship_mode_sk = 1
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT ch.c_customer_sk) > 10 
   OR SUM(COALESCE(ss.net_profit, 0)) > 1000 
ORDER BY total_net_profit DESC 
FETCH FIRST 10 ROWS ONLY;
