
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_store_returns,
        SUM(COALESCE(wr_return_quantity, 0)) AS total_web_returns,
        COUNT(DISTINCT sr_ticket_number) AS total_store_return_transactions,
        COUNT(DISTINCT wr_order_number) AS total_web_return_transactions
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_customer_id
),
ReturnStatistics AS (
    SELECT
        r.c_customer_sk,
        r.c_customer_id,
        r.total_store_returns,
        r.total_web_returns,
        r.total_store_return_transactions,
        r.total_web_return_transactions,
        (r.total_store_returns + r.total_web_returns) AS total_returns,
        (r.total_store_return_transactions + r.total_web_return_transactions) AS total_return_transactions,
        CASE WHEN (r.total_store_returns + r.total_web_returns) = 0 THEN 0
             ELSE (r.total_store_returns / NULLIF(r.total_store_return_transactions, 0)::decimal) END AS avg_store_return_quantity,
        CASE WHEN (r.total_web_returns + r.total_store_returns) = 0 THEN 0 
             ELSE (r.total_web_returns / NULLIF(r.total_web_return_transactions, 0)::decimal) END AS avg_web_return_quantity
    FROM
        CustomerReturns r
    JOIN customer c ON r.c_customer_sk = c.c_customer_sk
)
SELECT
    r.c_customer_id,
    r.total_returns,
    r.total_return_transactions,
    r.avg_store_return_quantity,
    r.avg_web_return_quantity,
    CASE
        WHEN r.total_returns > 100 THEN 'High'
        WHEN r.total_returns BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS return_frequency
FROM
    ReturnStatistics r
WHERE
    r.total_returns > 0
ORDER BY
    r.total_returns DESC
LIMIT 10;
