
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales,
        NULL AS parent_customer_sk
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT 
        c2.c_customer_sk,
        c2.c_first_name,
        c2.c_last_name,
        COALESCE(SUM(ss2.ss_net_profit), 0) AS total_sales,
        sh.c_customer_sk AS parent_customer_sk
    FROM 
        customer c2
    JOIN 
        store_sales ss2 ON c2.c_customer_sk = ss2.ss_customer_sk
    JOIN 
        SalesHierarchy sh ON c2.c_current_cdemo_sk = sh.c_customer_sk
    GROUP BY 
        c2.c_customer_sk, c2.c_first_name, c2.c_last_name, sh.c_customer_sk
),
SalesSummary AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesHierarchy
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales,
    COALESCE((SELECT COUNT(*)
               FROM store_sales ss
               WHERE ss.ss_customer_sk = sh.c_customer_sk), 0) AS purchase_count,
    CASE 
        WHEN sh.total_sales > 1000 THEN 'High'
        WHEN sh.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COALESCE(wp.wp_url, 'No Webpage') AS website_url
FROM 
    SalesSummary sh
LEFT JOIN 
    web_page wp ON sh.c_customer_sk = wp.wp_customer_sk
WHERE 
    sh.sales_rank <= 10
ORDER BY 
    sh.total_sales DESC
