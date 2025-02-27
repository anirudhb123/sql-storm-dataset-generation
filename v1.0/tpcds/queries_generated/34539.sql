
WITH RECURSIVE MonthlySales AS (
    SELECT 
        d_year,
        MONTH(d_date) AS month,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim ON date_dim.d_date_sk = web_sales.ws_sold_date_sk
    GROUP BY 
        d_year, MONTH(d_date)
    
    UNION ALL
    
    SELECT 
        d_year,
        month + 1,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    JOIN 
        date_dim ON date_dim.d_date_sk = web_sales.ws_sold_date_sk
    WHERE 
        month < 12
    GROUP BY 
        d_year, month
), RankedSales AS (
    SELECT 
        d_year,
        month,
        total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rank
    FROM 
        MonthlySales
), StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales 
    JOIN 
        store s ON s.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s.s_store_sk
), SalesComparison AS (
    SELECT 
        r.d_year,
        r.month,
        r.total_sales AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales
    FROM 
        RankedSales r
    LEFT JOIN 
        StoreSales ss ON ss.s_store_sk = r.d_year
)
SELECT 
    d_year,
    month,
    web_sales,
    store_sales,
    web_sales - store_sales AS sales_difference,
    CASE 
        WHEN web_sales > store_sales THEN 'Web Sales Higher'
        WHEN web_sales < store_sales THEN 'Store Sales Higher'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    SalesComparison
WHERE 
    (web_sales > 1000 OR store_sales > 1000)
ORDER BY 
    d_year, month;
