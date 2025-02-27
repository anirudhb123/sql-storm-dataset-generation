
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns,
        SUM(sr.return_amt) AS total_returned_amount,
        SUM(sr.return_quantity) AS total_returned_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
WebReturnStats AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(DISTINCT wr.order_number) AS total_web_returns,
        SUM(wr.return_amt_inc_tax) AS total_web_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
TotalReturns AS (
    SELECT 
        csr.c_customer_sk,
        csr.c_first_name,
        csr.c_last_name,
        COALESCE(csr.total_store_returns, 0) AS store_returns,
        COALESCE(csr.total_returned_amount, 0) AS store_returned_amount,
        COALESCE(csr.total_returned_quantity, 0) AS store_returned_quantity,
        COALESCE(wrs.total_web_returns, 0) AS web_returns,
        COALESCE(wrs.total_web_returned_amount, 0) AS web_returned_amount
    FROM 
        CustomerReturnStats csr
    FULL OUTER JOIN 
        WebReturnStats wrs ON csr.c_customer_sk = wrs.returning_customer_sk
)
SELECT 
    tr.c_customer_sk,
    tr.c_first_name,
    tr.c_last_name,
    tr.store_returns,
    tr.store_returned_amount,
    tr.store_returned_quantity,
    tr.web_returns,
    tr.web_returned_amount,
    RANK() OVER (ORDER BY (tr.store_returned_amount + tr.web_returned_amount) DESC) AS return_rank,
    CASE 
        WHEN tr.store_returned_amount > tr.web_returned_amount THEN 'Store Returns Dominant'
        WHEN tr.web_returned_amount > tr.store_returned_amount THEN 'Web Returns Dominant'
        ELSE 'Equal Returns'
    END AS return_dominance
FROM 
    TotalReturns tr
WHERE 
    (tr.store_returns + tr.web_returns) > 0
ORDER BY 
    return_rank
LIMIT 100;
