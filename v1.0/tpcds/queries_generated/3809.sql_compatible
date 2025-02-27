
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopProfitableItems AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        MAX(rs.ws_net_profit) AS max_profit
    FROM RankedSales rs
    INNER JOIN item ON rs.ws_item_sk = item.i_item_sk
    WHERE rs.profit_rank <= 5
    GROUP BY item.i_item_id, item.i_item_desc
),
CustomerReturns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_returning_customers
    FROM store_returns sr
    JOIN TopProfitableItems tpi ON sr.sr_item_sk = tpi.i_item_id
    GROUP BY sr.sr_item_sk
),
FinalSalesData AS (
    SELECT
        tpi.i_item_id,
        tpi.i_item_desc,
        COALESCE(cr.total_returns, 0) AS total_returns,
        tpi.max_profit
    FROM TopProfitableItems tpi
    LEFT JOIN CustomerReturns cr ON tpi.i_item_id = cr.sr_item_sk
)
SELECT
    fsd.i_item_id,
    fsd.i_item_desc,
    fsd.total_returns,
    fsd.max_profit,
    (CASE
        WHEN fsd.total_returns = 0 THEN 'No Returns'
        WHEN fsd.total_returns > 50 THEN 'High Return'
        ELSE 'Regular Return'
    END) AS return_category
FROM FinalSalesData fsd
ORDER BY fsd.max_profit DESC, fsd.total_returns ASC;
