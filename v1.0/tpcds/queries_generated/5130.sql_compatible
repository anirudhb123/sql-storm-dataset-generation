
WITH ReturnCounts AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_sales_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
CombinedData AS (
    SELECT
        COALESCE(rc.sr_item_sk, sd.ws_item_sk) AS item_sk,
        COALESCE(total_returns, 0) AS total_returns,
        COALESCE(total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(total_returned_amount, 0) AS total_returned_amount,
        COALESCE(total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(total_sales_profit, 0) AS total_sales_profit
    FROM
        ReturnCounts rc
    FULL OUTER JOIN
        SalesData sd ON rc.sr_item_sk = sd.ws_item_sk
)
SELECT
    item_sk,
    total_returns,
    total_returned_quantity,
    total_returned_amount,
    total_sales_quantity,
    total_sales_profit,
    CASE 
        WHEN total_sales_quantity > 0 THEN (total_returns::decimal / total_sales_quantity) * 100 
        ELSE 0 
    END AS return_rate_percentage
FROM
    CombinedData
WHERE
    (total_returns > 0 OR total_sales_quantity > 0)
ORDER BY
    return_rate_percentage DESC
LIMIT 10;
