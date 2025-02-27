
WITH SalesData AS (
    SELECT
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk DESC) AS sales_rank
    FROM
        web_sales AS ws
    INNER JOIN
        date_dim AS dd
    ON
        ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_ship_date_sk, ws.ws_item_sk
),
FilterSales AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        sd.total_sold_quantity,
        sd.total_sales_amount
    FROM
        SalesData AS sd
    INNER JOIN
        item AS item
    ON
        sd.ws_item_sk = item.i_item_sk
    WHERE
        sd.total_sold_quantity > 100
),
Returns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)
SELECT
    fs.i_item_id,
    fs.i_item_desc,
    fs.total_sold_quantity,
    fs.total_sales_amount,
    COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    (fs.total_sales_amount - COALESCE(r.total_returned_amount, 0)) AS net_sales_amount,
    CASE
        WHEN (fs.total_sales_amount - COALESCE(r.total_returned_amount, 0)) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS sales_performance
FROM
    FilterSales AS fs
LEFT JOIN
    Returns AS r
ON
    fs.i_item_id = r.sr_item_sk
ORDER BY
    net_sales_amount DESC
LIMIT 10;
