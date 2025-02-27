
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerSales
    WHERE 
        total_spent > 1000
),
ReturnData AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returned,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COALESCE(rd.total_returned, 0) AS total_returned,
    COALESCE(rd.return_count, 0) AS return_count,
    (tc.total_spent - COALESCE(rd.total_returned, 0)) AS net_spent
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnData rd ON tc.c_customer_sk = rd.returning_customer_sk
WHERE 
    (tc.rank <= 10 OR rd.return_count > 0)
ORDER BY 
    net_spent DESC;
