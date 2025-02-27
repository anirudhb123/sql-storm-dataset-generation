
WITH RECURSIVE DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
    UNION ALL
    SELECT 
        d.d_date,
        SUM(cs.cs_sales_price) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
),
AggregatedSales AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(ws.ws_sales_price), 0) AS web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS store_sales,
        COALESCE(SUM(ws.ws_sales_price), 0) + COALESCE(SUM(cs.cs_sales_price), 0) + COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
)
SELECT 
    d.d_date,
    a.web_sales,
    a.catalog_sales,
    a.store_sales,
    a.total_sales,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank,
    CASE 
        WHEN a.total_sales IS NULL THEN 'No Sales Data' 
        WHEN a.total_sales > 100000 THEN 'High Sales' 
        WHEN a.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales' 
        ELSE 'Low Sales' 
    END AS sales_category
FROM 
    AggregatedSales a
JOIN 
    date_dim d ON a.d_date = d.d_date
WHERE 
    d.d_dow IN (6, 0) -- Filter for weekends
ORDER BY 
    a.total_sales DESC;
