
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
), CalculatedReturns AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returned_quantity,
        SUM(rr.sr_return_amt) AS total_returned_amt,
        COUNT(*) AS return_count
    FROM RankedReturns rr
    WHERE rr.return_rank <= 10
    GROUP BY rr.sr_item_sk
), ItemSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws 
    GROUP BY ws.ws_item_sk
), TotalSales AS (
    SELECT 
        item.i_item_sk,
        COALESCE(is.total_sold_quantity, 0) AS total_sold,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        (COALESCE(is.total_sold_quantity, 0) - COALESCE(cr.total_returned_quantity, 0)) AS net_sales,
        (COALESCE(is.total_sold_quantity, 0) - COALESCE(cr.total_returned_quantity, 0)) * 1.0 / NULLIF(COALESCE(is.total_sold_quantity, 1), 1) AS return_rate
    FROM item item
    LEFT JOIN ItemSales is ON item.i_item_sk = is.ws_item_sk
    LEFT JOIN CalculatedReturns cr ON item.i_item_sk = cr.sr_item_sk
)
SELECT 
    ts.i_item_sk,
    ts.total_sold,
    ts.total_returned,
    ts.total_returned_amt,
    ts.net_sales,
    ts.return_rate,
    i.i_item_desc
FROM TotalSales ts
JOIN item i ON ts.i_item_sk = i.i_item_sk
WHERE ts.return_rate IS NOT NULL AND ts.return_rate > 0.1
  AND (ts.net_sales < 0 OR ts.returned_rate > 0.3)
ORDER BY ts.return_rate DESC
LIMIT 50;
