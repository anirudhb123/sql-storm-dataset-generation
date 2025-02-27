
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        RANK() OVER (ORDER BY cr.total_returned_quantity DESC) AS return_rank
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returned_quantity > 0
),
HighValueReturns AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COUNT(DISTINCT wr_return_number) AS web_return_count,
        SUM(wr_return_amt) AS total_web_returned_amount
    FROM 
        TopCustomers tc
    LEFT JOIN 
        web_returns wr ON tc.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        tc.c_customer_sk, tc.c_first_name, tc.c_last_name
    HAVING 
        SUM(wr_return_amt) > 1000
),
ReturnStatistics AS (
    SELECT 
        hvr.c_customer_sk,
        hvr.c_first_name,
        hvr.c_last_name,
        hvr.total_web_returned_amount,
        COALESCE(hvr.web_return_count, 0) AS web_return_count,
        COALESCE(c.total_return_count, 0) AS in_store_return_count
    FROM 
        HighValueReturns hvr
    LEFT JOIN 
        CustomerReturns c ON hvr.c_customer_sk = c.sr_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.web_return_count,
    r.in_store_return_count,
    r.total_web_returned_amount,
    (r.total_web_returned_amount / NULLIF(LEAST(r.web_return_count + r.in_store_return_count, 1), 1)) AS average_return_per_transaction
FROM 
    ReturnStatistics r
ORDER BY 
    average_return_per_transaction DESC
LIMIT 10;
