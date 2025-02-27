
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price > 0
),
TotalSales AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_ext_sales_price) AS total_ext_sales_price
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 5
    GROUP BY
        rs.ws_item_sk
),
ReturnDetails AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amt) AS total_return_amt,
        AVG(cr.cr_fee) AS avg_return_fee
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk IS NOT NULL
    GROUP BY
        cr.cr_item_sk
),
FinalResults AS (
    SELECT
        i.i_item_id,
        COALESCE(ts.total_ext_sales_price, 0) AS total_sales,
        COALESCE(rd.total_return_quantity, 0) AS total_returns,
        COALESCE(rd.total_return_amt, 0) AS return_amount,
        COALESCE(rd.avg_return_fee, 0) AS avg_fee,
        (COALESCE(ts.total_ext_sales_price, 0) - COALESCE(rd.total_return_amt, 0)) AS net_sales
    FROM
        item i
    LEFT JOIN
        TotalSales ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN
        ReturnDetails rd ON i.i_item_sk = rd.cr_item_sk
)
SELECT
    f.i_item_id,
    f.total_sales,
    f.total_returns,
    f.return_amount,
    f.avg_fee,
    CASE
        WHEN f.net_sales > 0 THEN 'Profitable'
        WHEN f.net_sales < 0 THEN 'Loss'
        ELSE 'Break-even'
    END AS profitability_status
FROM
    FinalResults f
WHERE
    f.total_sales IS NOT NULL
    AND f.total_returns > 0
ORDER BY
    f.net_sales DESC
FETCH FIRST 10 ROWS ONLY;
