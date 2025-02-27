
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS RankSales,
        COALESCE(ws.ws_ext_sales_price - ws.ws_ext_discount_amt, 0) AS NetSales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
AggregatedSales AS (
    SELECT
        rs.ws_item_sk,
        AVG(NetSales) AS AvgNetSales,
        SUM(NetSales) AS TotalNetSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
),
HighValueItems AS (
    SELECT 
        ais.ws_item_sk,
        ais.AvgNetSales
    FROM 
        AggregatedSales ais
    WHERE 
        ais.TotalNetSales > (SELECT AVG(TotalNetSales) FROM AggregatedSales)
),
MonthlyReturns AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS SalesMonth,
        COUNT(DISTINCT sr_return_number) AS TotalReturns,
        SUM(sr_return_amt) AS TotalReturnAmount
    FROM 
        store_returns sr
    JOIN 
        date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY 
        SalesMonth 
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(hvi.AvgNetSales, 0) AS AvgNetSalesForHighValueItems,
    m.Months,
    m.TotalReturns,
    m.TotalReturnAmount,
    CASE 
        WHEN m.TotalReturns > 100 THEN 
            'High Return Volume'
        ELSE 
            'Normal Return Volume'
    END AS ReturnVolumeCategory,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS FullName,
    (SELECT COUNT(DISTINCT wr_item_sk) FROM web_returns WHERE wr_returning_customer_sk = c.c_customer_sk) AS TotalWebReturns
FROM 
    customer c
LEFT JOIN 
    HighValueItems hvi ON hvi.ws_item_sk = (SELECT MIN(ws_item_sk) FROM web_sales)
JOIN 
    (SELECT 
        SalesMonth,
        SUM(TotalReturns) OVER (ORDER BY SalesMonth) AS Months,
        SUM(TotalReturnAmount) AS TotalReturnAmount
    FROM MonthlyReturns) m ON 1=1
WHERE 
    c.c_birth_year < (SELECT MIN(d_year) FROM date_dim WHERE d_dow = 1) 
ORDER BY 
    c.c_customer_id DESC
LIMIT 50;
