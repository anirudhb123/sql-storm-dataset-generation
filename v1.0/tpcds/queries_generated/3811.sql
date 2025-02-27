
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT('Purchase: $', ws.ws_ext_sales_price), '; ') AS detailed_purchases
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_returns, 0) AS total_returns,
    (tc.total_sales - COALESCE(cr.total_returns, 0)) AS net_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerReturns cr ON tc.c_customer_sk = cr.sr_customer_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    net_sales DESC;
