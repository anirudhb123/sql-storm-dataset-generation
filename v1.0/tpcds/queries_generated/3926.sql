
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS total_return_transactions
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_transactions,
        DENSE_RANK() OVER (ORDER BY cr.total_returns DESC) AS return_rank
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returns > 0
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_sales_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        DATEDIFF(CURRENT_DATE, MIN(ws_sold_date_sk)) AS days_since_first_order
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(sd.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.avg_order_value, 0) AS avg_order_value,
    tc.total_returns,
    tc.total_return_transactions,
    CASE 
        WHEN tc.return_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category,
    CASE 
        WHEN COALESCE(sd.days_since_first_order, 0) > 365 THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status
FROM 
    TopReturningCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    tc.return_rank, total_sales_profit DESC;
