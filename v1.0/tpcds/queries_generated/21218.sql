
WITH RecentReturns AS (
    SELECT
        sr.store_sk,
        sr.customer_sk,
        SUM(sr.return_quantity) AS total_returned,
        COUNT(DISTINCT sr.ticket_number) AS return_count
    FROM
        store_returns sr
    WHERE
        sr.returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_month = 'Y')
    GROUP BY
        sr.store_sk,
        sr.customer_sk
),
CustomerIncome AS (
    SELECT
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT c.c_email_address) AS email_count,
        SUM(hd.hd_dep_count) AS total_dependents
    FROM
        customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        c.c_customer_sk, hd.hd_income_band_sk
),
SalesAndReturns AS (
    SELECT
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS web_order_count,
        SUM(ws.net_paid) AS total_web_sales,
        COALESCE(rr.total_returned, 0) AS total_web_returns
    FROM
        web_sales ws
    LEFT JOIN RecentReturns rr ON ws.bill_customer_sk = rr.customer_sk
    GROUP BY
        ws.bill_customer_sk
)
SELECT
    ci.c_customer_sk,
    ci.income_band,
    sr.web_order_count,
    sr.total_web_sales,
    sr.total_web_returns,
    CASE
        WHEN sr.total_web_sales IS NULL OR sr.total_web_returns IS NULL THEN 'UNKNOWN'
        ELSE CASE WHEN sr.total_web_returns > 0 THEN 'RETURNED' ELSE 'NOT RETURNED' END
    END AS return_status,
    ROW_NUMBER() OVER (PARTITION BY ci.income_band ORDER BY sr.total_web_sales DESC) AS sales_rank
FROM
    CustomerIncome ci
JOIN SalesAndReturns sr ON ci.c_customer_sk = sr.bill_customer_sk
WHERE
    ci.email_count > 0
    AND (sr.total_web_sales > 100 OR ci.total_dependents > 3)
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.returning_customer_sk = ci.c_customer_sk
        AND wr.returned_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_current_year = 'Y' LIMIT 1)
    )
ORDER BY
    ci.income_band, return_status DESC, sales_rank
LIMIT 100;
