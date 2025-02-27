
WITH customer_sales AS (
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
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cs.total_web_sales IS NULL THEN 0 ELSE cs.total_web_sales END AS web_sales,
            CASE 
            WHEN cs.total_catalog_sales IS NULL THEN 0 ELSE cs.total_catalog_sales END AS catalog_sales,
            CASE 
            WHEN cs.total_store_sales IS NULL THEN 0 ELSE cs.total_store_sales END AS store_sales
    FROM 
        customer_sales cs
)
SELECT 
    customer_id,
    web_sales,
    catalog_sales,
    store_sales,
    (web_sales + catalog_sales + store_sales) AS total_sales
FROM 
    sales_summary
WHERE 
    (web_sales + catalog_sales + store_sales) > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
