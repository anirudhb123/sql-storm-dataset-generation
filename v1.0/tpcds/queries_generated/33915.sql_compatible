
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales 
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COALESCE(SUM(ss.ss_net_profit), 0) > 0
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(sh.total_sales, 0) * 1.1 AS total_sales 
    FROM SalesHierarchy sh
    JOIN customer c ON c.c_current_cdemo_sk = sh.c_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(sh.total_sales) AS total_sales,
    AVG(sh.total_sales) AS average_sales,
    MAX(sh.total_sales) AS max_sales,
    MIN(sh.total_sales) AS min_sales,
    (CASE 
        WHEN AVG(sh.total_sales) IS NULL THEN 'No Sales' 
        ELSE CONCAT('Average Sales: $', ROUND(AVG(sh.total_sales), 2)) 
     END) AS sales_summary
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
WHERE ca.ca_state = 'NY'
GROUP BY ca.ca_city
ORDER BY total_sales DESC
LIMIT 10;
