
WITH RECURSIVE TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS TotalProfit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS Rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS ReturnCount,
        SUM(sr_return_amt) AS TotalReturnAmt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND d_moy IN (1, 2, 3) 
        )
    GROUP BY 
        sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS TotalSalesProfit,
        COALESCE(cr.ReturnCount, 0) AS TotalReturns,
        COALESCE(cr.TotalReturnAmt, 0) AS TotalReturnAmount
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    GROUP BY 
        i.i_item_id
)

SELECT 
    s.ItemID,
    s.TotalSalesProfit,
    s.TotalReturns,
    s.TotalReturnAmount,
    CASE
        WHEN s.TotalSalesProfit > 0 THEN ROUND((s.TotalReturnAmount / s.TotalSalesProfit) * 100, 2)
        ELSE NULL
    END AS ReturnRatePercentage,
    t.Rank
FROM 
    SalesAndReturns s
JOIN 
    TopSellingItems t ON s.ItemID IN (SELECT i_item_id FROM item WHERE i_item_sk = t.ws_item_sk)
WHERE 
    t.Rank <= 10
ORDER BY 
    s.TotalSalesProfit DESC
