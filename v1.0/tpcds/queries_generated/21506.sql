
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid) AS dense_rank_paid
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price IS NOT NULL
        AND ws.ws_net_paid IS NOT NULL
),
TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_customer_sk) AS unique_customers_returned
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    COALESCE(SUM(CASE WHEN r.rank_profit = 1 THEN ws.ws_net_profit END), 0) AS max_net_profit,
    COALESCE(TR.total_returned_quantity, 0) AS total_returns,
    CASE 
        WHEN COALESCE(TR.total_returned_quantity, 0) > 0 THEN 
            SUM(ws.ws_quantity) / NULLIF(TR.total_returned_quantity, 0)
        ELSE 
            NULL 
    END AS sale_to_return_ratio,
    COUNT(DISTINCT CASE WHEN ws.ws_net_profit IS NOT NULL AND ws.ws_net_profit > 0 THEN ws.ws_order_number END) AS positive_profit_orders
FROM
    RankedSales r
JOIN
    TotalReturns TR ON r.ws_item_sk = TR.sr_item_sk
JOIN
    item i ON r.ws_item_sk = i.i_item_sk
JOIN
    web_sales ws ON r.ws_order_number = ws.ws_order_number
WHERE
    r.dense_rank_paid <= 5
GROUP BY
    i.i_item_id, i.i_item_desc
HAVING
    SUM(ws.ws_quantity) > 100
ORDER BY
    total_quantity_sold DESC;
