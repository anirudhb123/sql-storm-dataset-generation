
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.total_spent,
        cp.num_orders,
        cp.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.num_orders,
    tc.avg_order_value,
    (SELECT COUNT(DISTINCT sr.returned_date_sk) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS num_returns,
    (SELECT SUM(sr.return_amt) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_returned_amount
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
