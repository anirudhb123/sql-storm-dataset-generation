
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk, 
        ss_sold_date_sk, 
        SUM(ss_sales_price) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk, 
        d.d_date_sk, 
        SUM(ss.ss_sales_price) AS total_sales,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND sh.ss_sold_date_sk = ss.ss_sold_date_sk
    JOIN 
        date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        sh.s_store_sk, d.d_date_sk, sh.level
)

SELECT 
    ca.ca_city,
    SUM(COALESCE(sh.total_sales, 0)) AS total_sales,
    MIN(sh.total_sales) AS min_sales,
    MAX(sh.total_sales) AS max_sales,
    AVG(NULLIF(sh.total_sales, 0)) AS avg_sales,
    COUNT(DISTINCT sh.s_store_sk) AS store_count,
    STRING_AGG(DISTINCT CASE WHEN sh.total_sales IS NULL THEN 'No sales' ELSE 'Sales available' END, ', ') AS sales_status
FROM 
    SalesHierarchy sh
LEFT JOIN 
    store s ON sh.s_store_sk = s.s_store_sk
LEFT JOIN 
    customer_address ca ON s.s_street_number = ca.ca_street_number AND s.s_street_name = ca.ca_street_name
WHERE 
    s.s_number_employees IS NOT NULL 
GROUP BY 
    ca.ca_city
HAVING 
    SUM(COALESCE(sh.total_sales, 0)) > 10000
ORDER BY 
    total_sales DESC;
