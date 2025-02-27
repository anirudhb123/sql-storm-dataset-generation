
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_qty,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
ReturnSummary AS (
    SELECT 
        COALESCE(cr.wr_returning_customer_sk, sr.sr_customer_sk) AS customer_sk,
        COALESCE(cr.total_returned_qty, 0) + COALESCE(sr.total_returned_qty, 0) AS combined_returned_qty,
        COALESCE(cr.total_return_amount, 0) + COALESCE(sr.total_return_amount, 0) AS combined_return_amount
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        StoreReturns sr ON cr.wr_returning_customer_sk = sr.sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.combined_returned_qty,
        r.combined_return_amount
    FROM 
        ReturnSummary r
    JOIN 
        customer c ON r.customer_sk = c.c_customer_sk
    ORDER BY 
        r.combined_return_amount DESC
    LIMIT 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.combined_returned_qty,
    r.combined_return_amount
FROM 
    TopCustomers r
JOIN 
    customer c ON r.customer_sk = c.c_customer_sk;
