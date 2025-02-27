
WITH CustomerReturnSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_return_tax) AS total_web_return_tax
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreReturnSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(sr_return_tax) AS total_store_return_tax
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TotalReturns AS (
    SELECT 
        cr.c_customer_sk,
        COALESCE(cr.web_return_count, 0) + COALESCE(sr.store_return_count, 0) AS total_return_count,
        COALESCE(cr.total_web_return_amt, 0) + COALESCE(sr.total_store_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_web_return_tax, 0) + COALESCE(sr.total_store_return_tax, 0) AS total_return_tax
    FROM 
        CustomerReturnSummary cr
    FULL OUTER JOIN 
        StoreReturnSummary sr ON cr.c_customer_sk = sr.c_customer_sk
),
RankedReturns AS (
    SELECT 
        t.*,
        RANK() OVER (ORDER BY total_return_amt DESC) AS rank
    FROM 
        TotalReturns t
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    r.total_return_count,
    r.total_return_amt,
    r.total_return_tax,
    r.rank
FROM 
    RankedReturns r
JOIN 
    customer c ON r.c_customer_sk = c.c_customer_sk
WHERE 
    r.rank <= 10
ORDER BY 
    r.total_return_amt DESC;
