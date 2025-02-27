
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
ItemSales AS (
    SELECT
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_sales_value
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(is.total_sales, 0) AS total_sales,
        COALESCE(is.total_sales_value, 0) AS total_sales_value,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM
        item i
    LEFT JOIN
        ItemSales is ON i.i_item_sk = is.ws_item_sk
    LEFT JOIN
        (SELECT
            sr_item_sk,
            SUM(sr_return_quantity) AS total_return_quantity,
            SUM(sr_return_amt) AS total_return_amount
        FROM
            store_returns
        GROUP BY
            sr_item_sk) cr ON i.i_item_sk = cr.sr_item_sk
),
SalesAnalysis AS (
    SELECT
        ti.i_item_id,
        ti.total_sales,
        ti.total_sales_value,
        ti.total_return_quantity,
        ti.total_return_amount,
        (ti.total_sales_value - ti.total_return_amount) AS net_sales_value
    FROM
        TopItems ti
    WHERE
        ti.total_sales_value > 1000
)
SELECT
    sa.i_item_id,
    sa.total_sales,
    sa.total_sales_value,
    sa.total_return_quantity,
    sa.total_return_amount,
    sa.net_sales_value,
    RANK() OVER (ORDER BY sa.net_sales_value DESC) AS sales_rank
FROM
    SalesAnalysis sa
ORDER BY
    sales_rank
LIMIT 10;

