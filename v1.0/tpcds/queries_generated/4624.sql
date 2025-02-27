
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_return_value,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueReturns AS (
    SELECT *,
        CASE
            WHEN return_count > 3 THEN 'Frequent Returns'
            WHEN total_return_value > 1000 THEN 'High Value Returns'
            ELSE 'Regular Returns'
        END AS return_category
    FROM CustomerReturns
),
RecentSales AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_date >= DATEADD(month, -3, GETDATE())
    GROUP BY ws.bill_customer_sk
),
CustomerPerformance AS (
    SELECT
        hvr.c_customer_sk,
        hvr.c_first_name,
        hvr.c_last_name,
        hvr.total_returns,
        hvr.total_return_value,
        rv.total_sales,
        rv.order_count,
        hvr.return_category
    FROM HighValueReturns hvr
    LEFT JOIN RecentSales rv ON hvr.c_customer_sk = rv.bill_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    COALESCE(cp.total_sales, 0) AS total_sales,
    COALESCE(cp.total_returns, 0) AS total_returns,
    COALESCE(cp.return_category, 'No Returns') AS return_category,
    COALESCE(cp.order_count, 0) AS order_count,
    CASE
        WHEN cp.total_sales > 1000 AND cp.total_returns > 0 THEN 'High Sales, Returned Items'
        WHEN cp.total_sales <= 1000 AND cp.total_returns > 0 THEN 'Low Sales, Returned Items'
        ELSE 'No Returns or Low Sales'
    END AS performance_category
FROM customer c
LEFT JOIN CustomerPerformance cp ON c.c_customer_sk = cp.c_customer_sk
WHERE (cp.return_category IS NOT NULL OR cp.total_sales > 0)
ORDER BY c.c_last_name, c.c_first_name;
