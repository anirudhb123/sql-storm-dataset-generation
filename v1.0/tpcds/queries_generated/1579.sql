
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
SalesRanked AS (
    SELECT 
        c.c_customer_sk,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM CustomerSales c
),
IncomeGroups AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(COALESCE(cs.total_web_sales, 0)) AS avg_web_sales,
        AVG(COALESCE(cs.total_catalog_sales, 0)) AS avg_catalog_sales,
        AVG(COALESCE(cs.total_store_sales, 0)) AS avg_store_sales
    FROM household_demographics h
    LEFT JOIN CustomerSales cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY h.hd_income_band_sk
)
SELECT 
    ig.hd_income_band_sk,
    ig.customer_count,
    ig.avg_web_sales,
    ig.avg_catalog_sales,
    ig.avg_store_sales,
    CASE 
        WHEN ig.customer_count IS NULL OR ig.customer_count = 0 THEN 'No Sales Data'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM IncomeGroups ig
WHERE ig.customer_count > 10
ORDER BY ig.customer_count DESC
UNION ALL
SELECT 
    NULL AS hd_income_band_sk,
    COUNT(*) AS customer_count,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales,
    'Total Across All Income Bands' AS sales_data_status
FROM CustomerSales
WHERE total_web_sales + total_catalog_sales + total_store_sales > 0
HAVING COUNT(*) > 10;
