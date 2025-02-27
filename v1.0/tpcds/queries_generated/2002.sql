
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
SalesAnalysis AS (
    SELECT 
        c.customer_id,
        COALESCE(total_web_sales, 0) AS total_web_sales,
        COALESCE(total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(total_store_sales, 0) AS total_store_sales,
        total_web_sales + total_catalog_sales + total_store_sales AS total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    c.customer_id,
    c.total_web_sales,
    c.total_catalog_sales,
    c.total_store_sales,
    c.total_sales,
    CASE 
        WHEN c.total_sales = 0 THEN 'No Sales' 
        ELSE 'Has Sales' 
    END AS sales_status,
    DENSE_RANK() OVER (PARTITION BY sales_status ORDER BY total_sales DESC) AS status_rank
FROM 
    SalesAnalysis c
WHERE 
    c.total_sales > 1000
UNION ALL
SELECT 
    'Summary' AS customer_id,
    SUM(total_web_sales),
    SUM(total_catalog_sales),
    SUM(total_store_sales),
    SUM(total_sales),
    'Total Sales',
    NULL
FROM 
    SalesAnalysis
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC NULLS LAST;
