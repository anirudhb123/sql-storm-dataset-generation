
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS TotalSales, 
        COUNT(ws.ws_order_number) AS TotalOrders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_id, 
        c.first_name, 
        c.last_name, 
        cs.TotalSales, 
        cs.TotalOrders,
        ROW_NUMBER() OVER (ORDER BY cs.TotalSales DESC) AS SalesRank
    FROM 
        CustomerSales cs
    JOIN 
        (SELECT DISTINCT c_customer_id, c_first_name, c_last_name 
         FROM customer) c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id, 
    tc.first_name, 
    tc.last_name, 
    tc.TotalSales, 
    tc.TotalOrders 
FROM 
    TopCustomers tc
WHERE 
    tc.SalesRank <= 10
ORDER BY 
    tc.TotalSales DESC;
