
WITH RECURSIVE CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT COALESCE(sr_ticket_number, cr_order_number)) AS return_count
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY
        c.c_customer_sk
),
ItemReturns AS (
    SELECT
        ir.i_item_sk,
        SUM(sr_return_quantity) AS total_store_returns,
        SUM(cr_return_quantity) AS total_catalog_returns
    FROM
        item ir
    LEFT JOIN store_returns sr ON ir.i_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr ON ir.i_item_sk = cr.cr_item_sk
    GROUP BY
        ir.i_item_sk
),
SalesData AS (
    SELECT
        dc.d_year,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM
        date_dim dc
    LEFT JOIN web_sales ws ON dc.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON dc.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON dc.d_date_sk = ss.ss_sold_date_sk
    WHERE
        dc.d_year = 2023
    GROUP BY
        dc.d_year
)
SELECT
    c.c_customer_id,
    cr.total_returns,
    cr.return_count,
    id.i_item_sk,
    COALESCE(ir.total_store_returns, 0) AS total_store_returns,
    COALESCE(ir.total_catalog_returns, 0) AS total_catalog_returns,
    sd.total_web_sales,
    sd.total_catalog_sales,
    sd.total_store_sales
FROM
    CustomerReturns cr
JOIN customer c ON cr.c_customer_sk = c.c_customer_sk
LEFT JOIN ItemReturns ir ON ir.i_item_sk IN (SELECT DISTINCT i_item_sk FROM web_sales WHERE ws_ship_customer_sk = c.c_customer_sk)
CROSS JOIN SalesData sd
WHERE
    cr.total_returns > 0
ORDER BY
    cr.total_returns DESC,
    c.c_customer_id;
