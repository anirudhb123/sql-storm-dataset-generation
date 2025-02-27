
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesAndReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(ts.total_sales_amt, 0) AS total_sales_amt,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_returns, 0) AS total_returns
    FROM customer c
    LEFT JOIN TotalSales ts ON c.c_customer_sk = ts.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
),
RankedCustomers AS (
    SELECT 
        c.*,
        sar.total_sales_amt,
        sar.total_return_amt,
        sar.total_returns,
        RANK() OVER (ORDER BY sar.total_sales_amt - sar.total_return_amt DESC) AS sales_rank
    FROM customer c
    JOIN SalesAndReturns sar ON c.c_customer_sk = sar.c_customer_sk
)
SELECT 
    r.first_name,
    r.last_name,
    r.total_sales_amt,
    r.total_return_amt,
    r.total_returns,
    r.sales_rank,
    CASE 
        WHEN r.total_sales_amt - r.total_return_amt > 1000 THEN 'High Value Customer'
        WHEN r.total_sales_amt - r.total_return_amt BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM RankedCustomers r
WHERE r.sales_rank <= 10
ORDER BY r.sales_rank;
