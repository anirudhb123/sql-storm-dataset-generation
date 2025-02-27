
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS average_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
BestCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS first_purchase_date,
        DATEDIFF(CURRENT_DATE, d.d_date) AS days_since_first_purchase,
        ROW_NUMBER() OVER (ORDER BY COUNT(ws_order_number) DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
), 
HighlyActiveCustomers AS (
    SELECT 
        b.c_customer_sk,
        b.c_first_name,
        b.c_last_name,
        b.first_purchase_date,
        b.days_since_first_purchase
    FROM 
        BestCustomers b
    WHERE 
        b.purchase_rank <= 10
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    COALESCE(cr.total_returns, 0) AS num_returns,
    COALESCE(cr.total_return_amount, 0.00) AS total_return_amount,
    h.days_since_first_purchase,
    CASE 
        WHEN cr.total_returns > 0 THEN 'Returns' 
        ELSE 'No Returns' 
    END AS return_status,
    CASE 
        WHEN h.days_since_first_purchase <= 30 THEN 'New Customer'
        WHEN h.days_since_first_purchase <= 365 THEN 'Regular Customer'
        ELSE 'Loyal Customer'
    END AS customer_status
FROM 
    HighlyActiveCustomers h
LEFT JOIN 
    CustomerReturns cr ON h.c_customer_sk = cr.sr_customer_sk
ORDER BY 
    h.days_since_first_purchase DESC;
