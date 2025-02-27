
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk = 
        (SELECT MAX(ss_sub.ss_sold_date_sk) 
         FROM store_sales ss_sub 
         WHERE ss_sub.ss_sold_date_sk <= CURRENT_DATE)
    GROUP BY s.s_store_sk, s.s_store_name

    UNION ALL

    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE ss.ss_sold_date_sk < sh.ss_sold_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, ss.ss_sold_date_sk
),
performance_metrics AS (
    SELECT 
        sh.s_store_name,
        sh.ss_sold_date_sk,
        sh.total_sales,
        RANK() OVER (PARTITION BY sh.s_store_name ORDER BY sh.total_sales DESC) AS sales_rank,
        COUNT(*) OVER (PARTITION BY sh.s_store_name) AS total_sales_days
    FROM sales_hierarchy sh
),
top_sales AS (
    SELECT 
        p.s_store_name,
        p.total_sales,
        CASE
            WHEN p.total_sales > 1000 THEN 'High'
            WHEN p.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM performance_metrics p
    WHERE p.sales_rank = 1
)
SELECT 
    ca.ca_city,
    SUM(ts.total_sales) AS city_sales,
    COUNT(DISTINCT ts.s_store_name) AS number_of_stores,
    MAX(ts.total_sales) AS max_store_sales,
    MIN(ts.total_sales) AS min_store_sales,
    AVG(ts.total_sales) AS avg_store_sales
FROM top_sales ts
LEFT JOIN customer_address ca ON ts.s_store_name = ca.ca_city
GROUP BY ca.ca_city
HAVING city_sales > 5000 AND MAX(ts.total_sales) IS NOT NULL
ORDER BY city_sales DESC;
