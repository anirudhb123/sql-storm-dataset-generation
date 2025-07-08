
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_net_profit,
        1 AS level
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_net_profit > 0
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.ss_net_profit,
        level + 1
    FROM sales_hierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
    JOIN store_sales ss ON sh.ss_net_profit < ss.ss_net_profit
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_net_profit) AS avg_profit_per_customer,
    MAX(ss.ss_net_profit) AS max_profit_single_transaction
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ss.ss_sold_date_sk BETWEEN 2451910 AND 2451970
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_profit DESC 
LIMIT 10;
