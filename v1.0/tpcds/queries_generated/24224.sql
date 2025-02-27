
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank,
        COALESCE(ws.ws_net_profit, 0) AS NetProfit,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'Unknown'
            ELSE CASE 
                WHEN ws.ws_sales_price > 100 THEN 'High'
                WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'Medium'
                ELSE 'Low'
            END
        END AS Price_Category
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > 0
),
ItemReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS TotalReturns,
        SUM(cr.cr_return_amt_inc_tax) AS TotalReturnAmount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IS NOT NULL
    GROUP BY cr.cr_item_sk
),
JoinedData AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(rs.SalesRank, 0) AS SalesRank,
        COALESCE(ir.TotalReturns, 0) AS TotalReturns,
        COALESCE(ir.TotalReturnAmount, 0) AS TotalReturnAmount,
        CASE 
            WHEN COALESCE(ir.TotalReturns, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS Return_Status
    FROM item
    LEFT JOIN RankedSales rs ON item.i_item_sk = rs.ws_item_sk AND rs.SalesRank = 1
    LEFT JOIN ItemReturns ir ON item.i_item_sk = ir.cr_item_sk
),
FinalResults AS (
    SELECT 
        jd.*, 
        ROUND(jd.TotalReturnAmount / NULLIF(jd.TotalReturns, 0), 2) AS AvgReturnAmountPerItem,
        COUNT(DISTINCT js.ws_order_number) OVER (PARTITION BY jd.i_item_id) AS TotalOrdersForItem
    FROM JoinedData jd
    JOIN web_sales js ON jd.i_item_id = js.ws_item_sk
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.SalesRank,
    f.TotalReturns,
    f.TotalReturnAmount,
    f.Return_Status,
    f.AvgReturnAmountPerItem,
    f.TotalOrdersForItem,
    CASE 
        WHEN f.NetProfit > 500 THEN 'Profitable'
        ELSE 'Low Profit'
    END AS Profit_Status
FROM FinalResults f
WHERE f.SalesRank <= 5
AND f.NetProfit IS NOT NULL
ORDER BY f.TotalReturns DESC, f.i_item_id;
