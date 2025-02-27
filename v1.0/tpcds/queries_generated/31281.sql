
WITH RECURSIVE MonthlySales AS (
    SELECT 
        d.d_year AS Year,
        d.d_month_seq AS Month,
        SUM(ws.ws_net_paid) AS TotalSales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
    UNION ALL
    SELECT 
        Year,
        Month + 1,
        SUM(ws.ws_net_paid) 
    FROM 
        MonthlySales ms
    JOIN 
        date_dim d ON d.d_year = ms.Year AND d.d_month_seq = ms.Month + 1
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        ms.Month < 12
    GROUP BY 
        Year, Month
),
SalesStats AS (
    SELECT 
        Year,
        Month,
        TotalSales,
        RANK() OVER (PARTITION BY Year ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        MonthlySales
),
TopSales AS (
    SELECT 
        Year,
        Month,
        TotalSales
    FROM 
        SalesStats
    WHERE 
        SalesRank <= 3
)
SELECT 
    d.d_year,
    d.d_month_seq,
    COALESCE(ts.TotalSales, 0) AS TotalSales,
    COUNT(ws.ws_order_number) AS TotalOrders,
    AVG(ws.ws_net_paid) AS AvgOrderValue,
    SUM(CASE WHEN ws.ws_net_paid IS NULL THEN 1 ELSE 0 END) AS NullSalesCount
FROM 
    date_dim d
LEFT JOIN 
    TopSales ts ON d.d_year = ts.Year AND d.d_month_seq = ts.Month
LEFT JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
WHERE 
    d.d_year BETWEEN 2019 AND 2023
GROUP BY 
    d.d_year, d.d_month_seq
ORDER BY 
    d.d_year, d.d_month_seq;
