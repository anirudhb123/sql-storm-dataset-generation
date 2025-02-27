
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2451501 AND 2451507 -- Example date range
    GROUP BY
        ws_item_sk
),
top_items AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        rs.total_quantity,
        rs.total_profit
    FROM
        item i
    JOIN
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE
        rs.sales_rank <= 10
),
customer_return_statistics AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        AVG(wr_return_quantity) AS avg_return_quantity
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
returns_by_item AS (
    SELECT
        wr_items.wr_item_sk,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity
    FROM
        web_returns wr_items
    JOIN
        customer_return_statistics cr ON wr_items.wr_returning_customer_sk = cr.wr_returning_customer_sk
)
SELECT
    ti.i_product_name,
    ti.total_quantity,
    ti.total_profit,
    rbi.total_returns,
    rbi.total_return_amount,
    rbi.avg_return_quantity
FROM
    top_items ti
LEFT JOIN
    returns_by_item rbi ON ti.i_item_id = rbi.wr_item_sk
WHERE
    ti.total_profit > 5000
ORDER BY
    ti.total_profit DESC
LIMIT 20;
