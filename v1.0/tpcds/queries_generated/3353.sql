
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(sr_return_tax), 0) AS total_return_tax,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopReturningCustomers AS (
    SELECT 
        c.customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_returned,
        r.total_return_amt,
        RANK() OVER (ORDER BY r.total_returned DESC) as rank
    FROM 
        CustomerReturns r
    JOIN 
        customer c ON r.c_customer_sk = c.c_customer_sk
    WHERE 
        r.total_returned > 0
),
DailySales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
),
SalesWithAverage AS (
    SELECT 
        d.d_date,
        d.total_sales,
        d.total_profit,
        AVG(d.total_sales) OVER () AS avg_sales
    FROM 
        DailySales d
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned,
    tc.total_return_amt,
    sw.d_date,
    sw.total_sales,
    sw.total_profit,
    CASE 
        WHEN sw.total_sales IS NULL THEN 'No Sales'
        WHEN sw.total_sales > sw.avg_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    TopReturningCustomers tc
LEFT JOIN 
    SalesWithAverage sw ON tc.total_returned > 10  -- Highlighting customers with significant returns
WHERE 
    tc.rank <= 10  -- Selecting the top 10 returning customers
ORDER BY 
    tc.total_returned DESC, sw.d_date DESC;
