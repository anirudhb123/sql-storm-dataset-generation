
WITH RankedReturns AS (
    SELECT
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.returned_customer_sk,
        sr.return_quantity,
        sr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.return_quantity DESC) AS rnk
    FROM
        store_returns sr
    WHERE
        sr.return_amount > 0
),
TopReturns AS (
    SELECT
        rr.item_sk,
        SUM(rr.return_quantity) AS total_returned,
        SUM(rr.return_amt) AS total_return_amt
    FROM
        RankedReturns rr
    WHERE
        rr.rnk <= 5
    GROUP BY
        rr.item_sk
),
ItemSales AS (
    SELECT
        ws.item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    GROUP BY
        ws.item_sk
),
SalesAndReturns AS (
    SELECT
        i.i_item_sk,
        COALESCE(ts.total_sold, 0) AS total_sold,
        COALESCE(tr.total_returned, 0) AS total_returned,
        COALESCE(ts.total_net_profit, 0) AS total_net_profit
    FROM
        item i
    LEFT JOIN
        ItemSales ts ON i.i_item_sk = ts.item_sk
    LEFT JOIN
        TopReturns tr ON i.i_item_sk = tr.item_sk
)
SELECT
    sa.i_item_sk,
    sa.total_sold,
    sa.total_returned,
    sa.total_net_profit,
    (sa.total_net_profit - (sa.total_returned * 10.00)) AS adjusted_net_profit,
    CASE
        WHEN sa.total_returned > 0 
            THEN ROUND((sa.total_returned::decimal / NULLIF(sa.total_sold, 0)) * 100, 2) 
        ELSE NULL 
    END AS return_percentage,
    SUBSTRING(i.i_item_desc FROM 1 FOR 30) AS short_item_desc
FROM
    SalesAndReturns sa
JOIN
    item i ON sa.i_item_sk = i.i_item_sk
WHERE
    sa.adjusted_net_profit > 0
ORDER BY
    return_percentage DESC NULLS LAST, adjusted_net_profit DESC
FETCH FIRST 20 ROWS ONLY;
