
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        I.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY I.i_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item I ON ws.ws_item_sk = I.i_item_sk
    GROUP BY ws.ws_item_sk, I.i_item_desc
),
TopProducts AS (
    SELECT 
        rs.ws_item_sk,
        rs.i_item_desc,
        rs.total_quantity,
        rs.total_net_profit
    FROM RankedSales rs
    WHERE rs.profit_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned_qty,
        SUM(sr.sr_return_amt) AS total_returned_amt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
FinalReport AS (
    SELECT 
        tp.ws_item_sk,
        tp.i_item_desc,
        tp.total_quantity,
        tp.total_net_profit,
        COALESCE(cr.total_returned_qty, 0) AS returned_quantity,
        COALESCE(cr.total_returned_amt, 0) AS returned_amount,
        (tp.total_net_profit - COALESCE(cr.total_returned_amt, 0)) AS net_profit_after_returns
    FROM TopProducts tp
    LEFT JOIN CustomerReturns cr ON tp.ws_item_sk = cr.sr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.i_item_desc,
    f.total_quantity,
    f.total_net_profit,
    f.returned_quantity,
    f.returned_amount,
    f.net_profit_after_returns,
    CASE 
        WHEN f.net_profit_after_returns > 0 THEN 'Profitable'
        WHEN f.net_profit_after_returns = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_status
FROM FinalReport f
ORDER BY f.net_profit_after_returns DESC;
