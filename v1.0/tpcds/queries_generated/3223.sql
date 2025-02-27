
WITH CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
    GROUP BY
        sr_item_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_id,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_profit, 0) AS total_profit
    FROM
        item i
    LEFT JOIN CustomerReturns c ON i.i_item_sk = c.sr_item_sk
    LEFT JOIN SalesData s ON i.i_item_sk = s.ws_item_sk
)
SELECT
    ti.i_item_id,
    ti.total_returns,
    ti.total_sales,
    ti.total_profit,
    CASE
        WHEN ti.total_sales = 0 THEN 'No Sales'
        ELSE CAST(ti.total_profit AS DECIMAL(10, 2)) / NULLIF(ti.total_sales, 0)
    END AS profit_per_sale,
    RANK() OVER (ORDER BY ti.total_profit DESC) AS profit_rank
FROM
    TopItems ti
WHERE
    (ti.total_sales > 0 OR ti.total_returns > 0)
ORDER BY
    profit_rank
LIMIT 10;
