
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr_return_ticket_number) AS total_returns
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
        cr.total_return_amount,
        cr.total_returns,
        RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE 
        cr.total_return_amount > 1000
),
RecentSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_return_amount,
    rs.total_sales,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        WHEN tc.return_rank <= 10 THEN 'Top Returner'
        ELSE 'Regular Returner'
    END AS returner_category
FROM 
    TopCustomers tc
LEFT JOIN 
    RecentSales rs ON tc.sr_customer_sk = rs.bill_customer_sk
WHERE 
    tc.total_returns > 5
ORDER BY 
    tc.total_return_amount DESC, 
    rs.total_sales DESC;
