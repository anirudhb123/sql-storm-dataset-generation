
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt) AS total_return_amt, 
        COUNT(sr_returned_date_sk) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_amt,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rank
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE 
        cr.total_return_amt > 0
)
SELECT 
    tc.rank,
    tc.c_first_name, 
    tc.c_last_name,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    COALESCE((
        SELECT MAX(cr_return_amt_inc_tax)
        FROM catalog_returns
        WHERE cr_returning_customer_sk = tc.sr_customer_sk
    ), 0) AS max_catalog_return_amt,
    COALESCE((
        SELECT AVG(ws_sales_price)
        FROM web_sales ws
        WHERE ws_bill_customer_sk = tc.sr_customer_sk
        AND ws_dates_sk BETWEEN 20010101 AND 20231231
    ), 0) AS average_web_sales_price
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 20
ORDER BY 
    tc.rank;
