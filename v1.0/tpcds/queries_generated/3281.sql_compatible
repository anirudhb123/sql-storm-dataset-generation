
WITH SalesAggregate AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        sa.ws_item_sk,
        i.i_item_desc,
        sa.total_sales,
        sa.order_count
    FROM
        SalesAggregate sa
    JOIN
        item i ON sa.ws_item_sk = i.i_item_sk
    WHERE
        sa.sales_rank <= 10
),
ReturnsData AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt) AS return_amt
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
)
SELECT
    tsi.i_item_desc,
    tsi.total_sales,
    tsi.order_count,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.return_amt, 0) AS return_amt,
    (tsi.total_sales - COALESCE(rd.return_amt, 0)) AS net_sales
FROM
    TopSellingItems tsi
LEFT JOIN
    ReturnsData rd ON tsi.ws_item_sk = rd.cr_item_sk
ORDER BY
    net_sales DESC;
