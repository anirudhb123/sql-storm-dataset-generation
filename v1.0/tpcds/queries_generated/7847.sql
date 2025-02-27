
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.return_amt_inc_tax,
        COUNT(sr.return_quantity) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(sr.return_tax) AS total_return_tax
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_page_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_amt,
        cr.total_return_tax,
        sd.total_sales,
        sd.total_discount,
        sd.total_net_paid
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        SalesData sd ON cr.c_customer_id = (SELECT DISTINCT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sr.sr_customer_sk)
    WHERE 
        cr.total_returns > 0
)
SELECT 
    tc.c_customer_id,
    tc.total_returns,
    tc.total_return_amt,
    tc.total_return_tax,
    tc.total_sales,
    tc.total_discount,
    tc.total_net_paid
FROM 
    TopCustomers tc
WHERE 
    tc.total_net_paid > 0
ORDER BY 
    tc.total_return_amt DESC
LIMIT 100;
