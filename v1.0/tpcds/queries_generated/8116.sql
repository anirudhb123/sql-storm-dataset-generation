
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) as spend_rank
    FROM 
        CustomerSpend cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_spent > 500
)
SELECT 
    tc.customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    e.d_date AS purchase_date,
    e.t_time_id AS purchase_time
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.customer_id = ws.ws_bill_customer_sk
JOIN 
    date_dim e ON ws.ws_sold_date_sk = e.d_date_sk
JOIN 
    time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE 
    tc.spend_rank <= 10
ORDER BY 
    tc.total_spent DESC, purchase_date, purchase_time;
