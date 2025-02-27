
WITH RankedSales AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_id
),
TopWarehouses AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        COALESCE(MAX(rs.total_sales), 0) AS max_sales
    FROM
        warehouse w
    LEFT JOIN
        RankedSales rs ON w.w_warehouse_id = rs.w_warehouse_id
    GROUP BY
        w.w_warehouse_id, w.w_warehouse_name
),
CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COUNT(cr.cr_item_sk) AS return_count,
        SUM(cr.cr_return_amt) AS total_return_amt
    FROM
        customer c
    JOIN
        catalog_returns cr ON c.c_customer_sk = cr.cr_refunded_customer_sk
    GROUP BY
        c.c_customer_id
)
SELECT
    tw.w_warehouse_name,
    tw.max_sales,
    cr.c_customer_id,
    cr.return_count,
    cr.total_return_amt,
    CASE
        WHEN cr.return_count = 0 THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM
    TopWarehouses tw
FULL OUTER JOIN
    CustomerReturns cr ON tw.max_sales > 1000000 OR cr.return_count IS NOT NULL
WHERE
    tw.max_sales IS NOT NULL OR cr.return_count IS NOT NULL
ORDER BY
    tw.max_sales DESC, cr.total_return_amt DESC;
