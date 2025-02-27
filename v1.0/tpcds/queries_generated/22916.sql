
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 1
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2457361 AND 2457730
    GROUP BY 
        ws_bill_customer_sk
),
SalesRank AS (
    SELECT 
        c.c_customer_id,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_amt,
        sr.total_net_profit,
        sr.rank
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        SalesRank sr ON cr.sr_customer_sk = sr.c_customer_id
)
SELECT 
    tc.sr_customer_sk,
    COALESCE(tc.return_count, 0) AS return_count,
    COALESCE(tc.total_return_amt, 0) AS total_return_amt,
    COALESCE(sr.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN sr.rank IS NOT NULL AND tc.return_count > 0 THEN 'High Return Customer'
        WHEN sr.rank IS NULL THEN 'No Sales'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    CustomerReturns cr ON tc.sr_customer_sk = cr.sr_customer_sk
WHERE 
    (tc.return_count IS NOT NULL OR sr.rank IS NOT NULL)
ORDER BY 
    customer_status, return_count DESC, total_net_profit DESC;
