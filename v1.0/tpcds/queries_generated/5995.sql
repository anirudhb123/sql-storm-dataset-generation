
WITH TotalSales AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
),
SalesGrowth AS (
    SELECT
        d_year,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        LAG(total_web_sales) OVER (ORDER BY d_year) AS prev_web_sales,
        LAG(total_catalog_sales) OVER (ORDER BY d_year) AS prev_catalog_sales,
        LAG(total_store_sales) OVER (ORDER BY d_year) AS prev_store_sales
    FROM 
        TotalSales
)
SELECT 
    d_year,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    CASE 
        WHEN prev_web_sales IS NULL THEN NULL 
        ELSE (total_web_sales - prev_web_sales) / prev_web_sales * 100 
    END AS web_sales_growth,
    CASE 
        WHEN prev_catalog_sales IS NULL THEN NULL 
        ELSE (total_catalog_sales - prev_catalog_sales) / prev_catalog_sales * 100 
    END AS catalog_sales_growth,
    CASE 
        WHEN prev_store_sales IS NULL THEN NULL 
        ELSE (total_store_sales - prev_store_sales) / prev_store_sales * 100 
    END AS store_sales_growth
FROM 
    SalesGrowth
ORDER BY 
    d_year;
