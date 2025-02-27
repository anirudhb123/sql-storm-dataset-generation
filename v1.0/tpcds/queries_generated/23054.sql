
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rnk
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        CASE 
            WHEN SUM(sr_return_amt_inc_tax) IS NULL THEN 0
            ELSE SUM(sr_return_amt_inc_tax) 
        END AS adjusted_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesVsReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        ISNULL(rs.total_returns, 0) AS total_returns,
        ISNULL(rs.total_returned_amt, 0) AS total_returned_amt,
        r.total_net_paid - ISNULL(rs.total_returned_amt, 0) AS net_profit_after_returns
    FROM RankedSales r
    LEFT JOIN ReturnStats rs ON r.ws_item_sk = rs.sr_item_sk
    WHERE rnk = 1
),
ItemInfo AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        CASE 
            WHEN i.i_size IS NULL THEN 'Unknown Size'
            ELSE i.i_size
        END AS item_size
    FROM item i
)
SELECT 
    ii.i_item_id,
    ii.i_item_desc,
    sv.total_quantity,
    sv.total_net_paid,
    sv.total_returns,
    sv.total_returned_amt,
    sv.net_profit_after_returns,
    CASE 
        WHEN sv.net_profit_after_returns > 0 THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS profitability_status
FROM SalesVsReturns sv
JOIN ItemInfo ii ON sv.ws_item_sk = ii.i_item_sk
WHERE sv.net_profit_after_returns < 0 
   OR (sv.total_quantity > 100 AND sv.total_returns / NULLIF(sv.total_quantity, 0) > 0.1)
ORDER BY sv.net_profit_after_returns DESC;

