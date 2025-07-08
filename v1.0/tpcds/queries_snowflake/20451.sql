
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rank,
        COALESCE(NULLIF(SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk), 0), 1) AS total_quantity
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2400 AND 2600
),
ReturnDetails AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        COALESCE((SELECT r.r_reason_desc FROM reason r WHERE r.r_reason_sk = cr.cr_reason_sk), 'Not Specified') AS reason_desc
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk IS NOT NULL
),
FinalComparison AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_sales_price,
        rd.cr_return_quantity,
        rd.cr_return_amount,
        rd.reason_desc,
        CASE 
            WHEN rd.cr_return_amount IS NULL THEN 'No Returns'
            WHEN rd.cr_return_quantity > rs.ws_quantity THEN 'Excess Return'
            ELSE 'Normal Return'
        END AS return_status
    FROM
        RankedSales rs
    LEFT JOIN
        ReturnDetails rd ON rs.ws_order_number = rd.cr_order_number
)
SELECT
    f.ws_order_number,
    f.ws_item_sk,
    SUM(f.ws_quantity) * AVG(f.ws_sales_price) AS total_revenue,
    SUM(CASE WHEN f.return_status = 'Normal Return' THEN f.cr_return_quantity ELSE 0 END) AS total_normal_returns,
    SUM(CASE WHEN f.return_status = 'Excess Return' THEN f.cr_return_quantity ELSE 0 END) AS total_excess_returns,
    COUNT(DISTINCT f.return_status) AS distinct_return_statuses,
    MAX(CASE WHEN f.return_status = 'No Returns' THEN 'Yes' ELSE 'No' END) AS any_no_returns
FROM
    FinalComparison f
GROUP BY
    f.ws_order_number, f.ws_item_sk
HAVING
    SUM(f.ws_quantity) > 10
ORDER BY
    total_revenue DESC
LIMIT 100;
