
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY
        ws.web_site_id
),
CustomerReturns AS (
    SELECT
        wr.w_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM
        web_returns wr
    WHERE
        wr.wr_returned_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY
        wr.w_web_page_sk
)
SELECT
    sd.web_site_id,
    sd.total_sales,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    sd.order_count,
    cr.return_count,
    CASE
        WHEN sd.total_sales = 0 THEN 0
        ELSE (COALESCE(cr.total_return_amount, 0) / sd.total_sales) * 100
    END AS return_percentage
FROM
    SalesData sd
LEFT JOIN
    CustomerReturns cr ON sd.web_site_id = cr.w_web_page_sk
WHERE
    sd.sales_rank = 1
ORDER BY
    sd.total_sales DESC;
