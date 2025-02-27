
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_order_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        c.c_first_name,
        c.c_last_name
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE cr.total_returns > 0
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returns,
    tc.total_returned_quantity,
    tc.total_returned_amount,
    COALESCE(d.d_day_name, 'Unknown') AS return_day,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
FROM TopCustomers tc
LEFT JOIN web_sales ws ON tc.sr_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_returns, 
    tc.total_returned_quantity, 
    tc.total_returned_amount, 
    d.d_day_name
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000 OR COUNT(ws.ws_order_number) = 0
ORDER BY tc.total_returned_amount DESC
LIMIT 10;
