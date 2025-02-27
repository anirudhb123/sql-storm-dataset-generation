
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesData AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_return_quantity,
        cr.total_return_amount,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        RANK() OVER (ORDER BY COALESCE(sd.total_sales_amount, 0) - cr.total_return_amount DESC) AS sales_rank
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        SalesData sd ON cr.c_customer_sk = sd.bill_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_return_quantity,
    r.total_return_amount,
    r.total_sales_quantity,
    r.total_sales_amount,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top Customer'
        WHEN r.total_sales_quantity = 0 THEN 'No Purchases'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    RankedCustomers r
WHERE 
    r.total_return_quantity > 5 OR r.total_sales_quantity > 0
ORDER BY 
    r.sales_rank;
