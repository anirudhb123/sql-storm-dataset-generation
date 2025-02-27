
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1970
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_spent,
    ws.w_web_site_id,
    d.d_month_seq,
    d.d_year
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    tc.rank <= 10
    AND d.d_year = 2023
ORDER BY 
    cs.total_spent DESC;
