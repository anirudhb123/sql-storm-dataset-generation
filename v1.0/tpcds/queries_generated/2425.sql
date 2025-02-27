
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS customer_name, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
TopCustomers AS (
    SELECT 
        customer_name,
        total_spent,
        order_count,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerSales
),
StoresWithReturns AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT sr.ticket_number) AS return_count,
        SUM(sr.return_amount) AS total_returns
    FROM 
        store s
    LEFT JOIN 
        store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    tc.customer_name, 
    tc.total_spent, 
    tc.order_count,
    swr.store_name,
    swr.return_count,
    swr.total_returns
FROM 
    TopCustomers tc
JOIN 
    (SELECT 
         s.s_store_sk, 
         s.s_store_name
     FROM 
         store s 
     JOIN 
         StoresWithReturns sr ON s.s_store_sk = sr.s_store_sk
     WHERE 
         sr.return_count > 0) swr ON tc.order_count > 5
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
