
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_net_loss) AS total_return_net_loss,
        COALESCE(SUM(wr_return_amt), 0) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_return_net_loss, 0) AS total_return_net_loss,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    s.total_net_profit,
    s.total_returned_quantity,
    s.total_return_net_loss,
    s.total_return_amount,
    s.total_net_profit - s.total_return_net_loss AS net_profit_after_returns,
    CASE 
        WHEN s.total_quantity = 0 THEN NULL 
        ELSE ROUND((s.total_returned_quantity::decimal / NULLIF(s.total_quantity, 0)) * 100, 2) 
    END AS return_percentage,
    CONCAT('Item ', s.ws_item_sk, ' has ', s.total_returned_quantity, ' returns') AS return_summary
FROM 
    SalesAndReturns s
WHERE 
    s.total_net_profit > 0
ORDER BY 
    return_percentage DESC
LIMIT 10;
