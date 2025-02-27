
WITH SalesData AS (
    SELECT 
        cs.cs_sold_date_sk AS SaleDate,
        SUM(cs.cs_sales_price) AS TotalSales,
        SUM(cs.cs_net_profit) AS TotalProfit,
        COUNT(DISTINCT cs.cs_order_number) AS OrderCount,
        s.s_store_name AS StoreName,
        d.d_month_seq AS MonthSeq,
        d.d_year AS Year
    FROM 
        catalog_sales cs
    JOIN 
        store s ON cs.cs_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_name, d.d_month_seq, d.d_year
),
StorePerformance AS (
    SELECT 
        StoreName,
        MonthSeq,
        Year,
        TotalSales,
        TotalProfit,
        OrderCount,
        RANK() OVER (PARTITION BY MonthSeq ORDER BY TotalSales DESC) AS SalesRank,
        RANK() OVER (PARTITION BY MonthSeq ORDER BY TotalProfit DESC) AS ProfitRank
    FROM 
        SalesData
)
SELECT 
    StoreName,
    MonthSeq,
    Year,
    TotalSales,
    TotalProfit,
    OrderCount,
    SalesRank,
    ProfitRank
FROM 
    StorePerformance
WHERE 
    SalesRank <= 5 OR ProfitRank <= 5
ORDER BY 
    MonthSeq, SalesRank, ProfitRank;
