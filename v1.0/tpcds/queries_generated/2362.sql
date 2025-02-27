
WITH CustomerReturnStatistics AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
        COALESCE(
            SUM(wr.wr_return_amt_inc_tax), 0
        ) + COALESCE(
            SUM(sr.sr_return_amt_inc_tax), 0
        ) AS total_return_amount
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id
),
TopReturnCustomers AS (
    SELECT 
        ccs.c_customer_id,
        ccs.total_return_amount,
        RANK() OVER (ORDER BY ccs.total_return_amount DESC) AS rnk
    FROM CustomerReturnStatistics ccs
    WHERE ccs.total_return_amount > 0
)
SELECT 
    t.rc_date,
    COALESCE(SUM(CASE WHEN trc.rnk <= 10 THEN trc.total_return_amount ELSE 0 END), 0) AS top_10_returns,
    COALESCE(SUM(CASE WHEN trc.rnk > 10 THEN trc.total_return_amount ELSE 0 END), 0) AS others_returns
FROM date_dim t
LEFT JOIN TopReturnCustomers trc ON t.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= CURRENT_DATE)
GROUP BY t.rc_date
ORDER BY t.rc_date DESC;
