
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cr.total_return_quantity, 
        cr.total_return_amt,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_rank
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_return_quantity > 0
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk, 
        SUM(ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_ship_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name, 
    COALESCE(sd.total_sales, 0) AS total_sales, 
    tc.total_return_quantity, 
    tc.total_return_amt, 
    sd.total_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_id = sd.customer_sk
WHERE 
    tc.return_rank <= 10 AND (sd.total_sales IS NOT NULL OR tc.total_return_amt > 100)
ORDER BY 
    tc.total_return_amt DESC, 
    total_sales DESC;
