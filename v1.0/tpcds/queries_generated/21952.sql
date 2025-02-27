
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS TotalQuantity,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_item_sk) AS OrderCount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
), 
TotalReturns AS (
    SELECT 
        SUM(wr_return_quantity) AS TotalWebReturns,
        wr_item_sk
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), 
StoreSalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS TotalProfit,
        COUNT(DISTINCT ss.ss_ticket_number) AS UniqueTickets
    FROM 
        store_sales ss 
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    COALESCE(isS.ws_item_sk, s.ws_item_sk) AS Item_SK,
    COALESCE(isS.TotalProfit, 0) AS TotalProfit,
    COALESCE(rs.PriceRank, 0) AS PriceRank,
    COALESCE(tr.TotalWebReturns, 0) AS TotalReturns,
    CASE 
        WHEN tr.TotalWebReturns > 0 THEN 'Returns Recorded'
        ELSE 'No Returns'
    END AS ReturnStatus,
    (TotalProfit * 0.01) / NULLIF(TotalQuantity, 0) AS ProfitPerUnit
FROM 
    StoreSalesData isS
FULL OUTER JOIN RankedSales rs ON isS.ss_item_sk = rs.ws_item_sk 
LEFT JOIN TotalReturns tr ON rs.ws_item_sk = tr.wr_item_sk 
WHERE 
    (isS.TotalProfit IS NOT NULL OR rs.PriceRank IS NOT NULL)
    AND (rs.TotalQuantity IS NULL OR rs.PriceRank = 1)
ORDER BY 
    COALESCE(isS.TotalProfit, 0) DESC, 
    COALESCE(tr.TotalWebReturns, 0) DESC;
