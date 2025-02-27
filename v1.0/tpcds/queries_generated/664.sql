
WITH RankedSales AS (
    SELECT
        ss.sold_date_sk,
        ss.store_sk,
        ss.item_sk,
        ss.ticket_number,
        SUM(ss.ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ss.sold_date_sk, ss.store_sk, ss.item_sk, ss.ticket_number
),
TopStores AS (
    SELECT
        store_sk,
        SUM(total_sales) AS store_sales_total
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
    GROUP BY
        store_sk
),
CustomerReturns AS (
    SELECT
        wr_returned_date_sk,
        wr.returning_customer_sk,
        SUM(wr.return_amt) AS total_return_amount,
        COUNT(wr.return_quantity) AS total_returned_items
    FROM
        web_returns wr
    GROUP BY
        wr_returned_date_sk, wr.returning_customer_sk
),
StoreReturns AS (
    SELECT
        sr.returned_date_sk,
        sr.store_sk,
        SUM(sr.return_amt_inc_tax) AS total_store_return_amount,
        COUNT(sr.return_quantity) AS total_store_returned_items
    FROM
        store_returns sr
    GROUP BY
        sr.returned_date_sk, sr.store_sk
)
SELECT
    ws.web_site_id,
    w.warehouse_name,
    COALESCE(ts.store_sales_total, 0) AS total_sales,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sr.total_store_return_amount, 0) AS total_store_return_amount,
    (COALESCE(ts.store_sales_total, 0) - COALESCE(cr.total_return_amount, 0) - COALESCE(sr.total_store_return_amount, 0)) AS net_sales
FROM
    web_site ws
LEFT JOIN
    warehouse w ON ws.web_site_sk = w.warehouse_sk
LEFT JOIN
    TopStores ts ON w.warehouse_sk = ts.store_sk
LEFT JOIN
    CustomerReturns cr ON ws.web_site_sk = cr.returning_customer_sk
LEFT JOIN
    StoreReturns sr ON w.warehouse_sk = sr.store_sk
WHERE
    (ts.store_sales_total IS NOT NULL OR cr.total_return_amount IS NOT NULL OR sr.total_store_return_amount IS NOT NULL)
ORDER BY
    net_sales DESC;
