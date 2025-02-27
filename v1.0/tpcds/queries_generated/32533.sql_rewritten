WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451926 AND 2452026 
    GROUP BY ss_store_sk
    UNION ALL
    SELECT 
        s.s_store_sk,
        SH.total_sales,
        SH.unique_customers,
        SH.level + 1
    FROM sales_hierarchy SH
    JOIN store s ON SH.ss_store_sk = s.s_store_sk
    WHERE SH.level < 5 
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(SH.total_sales, 0) AS total_sales,
    COALESCE(SH.unique_customers, 0) AS unique_customers,
    CASE 
        WHEN COALESCE(SH.total_sales, 0) > 1000 THEN 'High Performer'
        WHEN COALESCE(SH.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Average Performer'
        ELSE 'Low Performer' 
    END AS performance_category,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    ROUND(AVG(ss_net_paid), 2) AS average_sales_per_transaction
FROM store s
LEFT JOIN sales_hierarchy SH ON s.s_store_sk = SH.ss_store_sk
LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE s.s_state = 'CA'
GROUP BY s.s_store_id, s.s_store_name, SH.total_sales, SH.unique_customers
ORDER BY total_sales DESC 
LIMIT 10;