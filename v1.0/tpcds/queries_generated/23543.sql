
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_items,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_qty) AS avg_return_qty
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_quantity) AS total_web_returned_items,
        SUM(wr_return_amt) AS total_web_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
ReturnStats AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(cr.total_returns, 0) AS total_store_returns,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        CASE
            WHEN COALESCE(cr.total_returns, 0) + COALESCE(wr.total_web_returns, 0) = 0 
            THEN NULL
            ELSE (COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_web_return_amount, 0)) /
                 (COALESCE(cr.total_returns, 0) + COALESCE(wr.total_web_returns, 0))
        END AS average_return_amount
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.sr_customer_sk = wr.wr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        cs.c_customer_id,
        rs.customer_sk,
        (rs.total_store_returns + rs.total_web_returns) AS total_returns
    FROM ReturnStats rs
    JOIN customer cs ON rs.customer_sk = cs.c_customer_sk
    WHERE (rs.total_store_returns + rs.total_web_returns) > (
        SELECT AVG(total_returns) FROM (
            SELECT (COALESCE(total_store_returns, 0) + COALESCE(total_web_returns, 0)) AS total_returns
            FROM ReturnStats
        ) AS avg_returns
    )
)
SELECT 
    cu.c_first_name || ' ' || cu.c_last_name AS customer_name,
    cu.c_email_address,
    t.total_returns,
    ROW_NUMBER() OVER (PARTITION BY cu.c_customer_id ORDER BY t.total_returns DESC) AS return_rank
FROM TopReturningCustomers t
JOIN customer cu ON t.customer_sk = cu.c_customer_sk
WHERE t.total_returns > 0
ORDER BY t.total_returns DESC
LIMIT 10;
