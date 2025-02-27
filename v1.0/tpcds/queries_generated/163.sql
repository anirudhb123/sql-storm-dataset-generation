
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
AggregateSales AS (
    SELECT
        w.w_warehouse_name,
        SUM(r.ws_sales_price) AS total_sales,
        COUNT(DISTINCT r.ws_web_site_sk) AS unique_sites,
        COUNT(*) AS total_transactions
    FROM
        RankedSales r
    LEFT JOIN
        warehouse w ON r.web_site_sk = w.w_warehouse_sk
    WHERE
        r.sales_rank <= 5
    GROUP BY
        w.w_warehouse_name
),
CustomerReturns AS (
    SELECT
        sr.refunded_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        AVG(sr_return_amt_inc_tax) AS avg_return_amount
    FROM
        store_returns sr
    WHERE
        sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY
        sr.refunded_customer_sk
)
SELECT
    ag.warehouse_name,
    ag.total_sales,
    ag.unique_sites,
    ag.total_transactions,
    cr.total_returned_quantity,
    cr.avg_return_amount
FROM
    AggregateSales ag
LEFT JOIN
    CustomerReturns cr ON ag.unique_sites > 0 AND cr.refunded_customer_sk IS NOT NULL
WHERE
    ag.total_sales > (SELECT AVG(total_sales) FROM AggregateSales)
ORDER BY
    ag.total_sales DESC;
