
WITH aggregated_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        customer_id, 
        total_spent, 
        total_orders, 
        average_profit_per_order,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        aggregated_sales
)
SELECT 
    tc.customer_id,
    tc.total_spent,
    tc.total_orders,
    tc.average_profit_per_order,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq
FROM 
    top_customers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
