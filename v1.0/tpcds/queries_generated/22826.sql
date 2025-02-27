
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank
    FROM web_sales
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_sales_price > 0
),
FilteredReturns AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS TotalReturns, 
        AVG(wr_return_amt_inc_tax) AS AvgReturnAmount
    FROM web_returns
    GROUP BY wr_item_sk
    HAVING SUM(wr_return_quantity) > 0
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_sales_price) AS TotalSales, 
        COALESCE(fr.TotalReturns, 0) AS TotalReturns, 
        COALESCE(fr.AvgReturnAmount, 0) AS AvgReturnAmount
    FROM RankedSales rs
    LEFT JOIN FilteredReturns fr ON rs.ws_item_sk = fr.wr_item_sk
    GROUP BY rs.ws_item_sk
)

SELECT 
    s.ws_item_sk,
    s.TotalSales,
    s.TotalReturns,
    CASE 
        WHEN s.TotalSales = 0 THEN NULL 
        ELSE (s.TotalReturns::decimal / NULLIF(s.TotalSales, 0)) * 100 
    END AS ReturnRate,
    COUNT(DISTINCT CASE WHEN rs.SalesRank = 1 THEN rs.ws_order_number END) AS BestSellersCount
FROM SalesWithReturns s
JOIN RankedSales rs ON s.ws_item_sk = rs.ws_item_sk
WHERE 
    (s.TotalSales > 1000 OR s.TotalReturns > 10)
    AND (EXISTS (SELECT 1 FROM catalog_sales cs WHERE cs.cs_item_sk = s.ws_item_sk AND cs.cs_net_profit > 50))
GROUP BY 
    s.ws_item_sk, 
    s.TotalSales, 
    s.TotalReturns
ORDER BY ReturnRate DESC, s.TotalSales DESC;
