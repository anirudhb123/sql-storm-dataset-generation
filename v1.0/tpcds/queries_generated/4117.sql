
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cs.total_orders,
        cs.total_spent
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 1 AND cs.total_spent IS NOT NULL
),
HighSpenders AS (
    SELECT 
        customer_sk,
        total_spent,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        TopCustomers
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM TopCustomers)
)
SELECT 
    c_first_name, 
    c_last_name, 
    total_orders, 
    total_spent 
FROM 
    HighSpenders
WHERE 
    spend_rank <= 10
ORDER BY 
    total_spent DESC;
