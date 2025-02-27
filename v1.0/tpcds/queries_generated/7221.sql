
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
),
TopReturns AS (
    SELECT
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returned_quantity,
        SUM(rr.sr_return_amt) AS total_returned_amount,
        SUM(rr.sr_return_tax) AS total_returned_tax
    FROM
        RankedReturns rr
    WHERE
        rr.rn <= 5
    GROUP BY
        rr.sr_item_sk
),
ItemSales AS (
    SELECT
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales_count,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
SalesReturnsRatio AS (
    SELECT
        is.ws_item_sk,
        COALESCE(tr.total_returned_quantity, 0) AS total_returned_quantity,
        is.total_sales_quantity,
        CASE 
            WHEN is.total_sales_quantity = 0 THEN 0
            ELSE CAST(COALESCE(tr.total_returned_quantity, 0) AS DECIMAL) / NULLIF(is.total_sales_quantity, 0)
        END AS return_ratio,
        is.total_net_profit
    FROM
        ItemSales is
    LEFT JOIN
        TopReturns tr ON is.ws_item_sk = tr.sr_item_sk
)
SELECT
    s.ws_item_sk,
    i.i_item_desc,
    ss.return_ratio,
    SUM(ss.total_net_profit) AS total_net_profit,
    COUNT(ss.ws_item_sk) AS total_transactions
FROM
    SalesReturnsRatio ss
JOIN
    item i ON ss.ws_item_sk = i.i_item_sk
WHERE
    ss.return_ratio > 0.1
GROUP BY
    s.ws_item_sk, i.i_item_desc, ss.return_ratio
ORDER BY
    return_ratio DESC, total_net_profit DESC
LIMIT 10;
