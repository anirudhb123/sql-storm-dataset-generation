
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_spent, 
        COUNT(ws.ws_order_number) AS num_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesStatistics AS (
    SELECT 
        total_spent, 
        num_orders, 
        avg_order_value,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_spent,
        RANK() OVER (ORDER BY num_orders DESC) AS rank_orders
    FROM 
        CustomerSales
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.total_spent, 
    cs.num_orders, 
    cs.avg_order_value,
    ss.rank_spent,
    ss.rank_orders,
    d.d_year, 
    d.d_month_seq
FROM 
    CustomerSales cs
JOIN 
    SalesStatistics ss ON cs.c_customer_sk = ss.c_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_sk)
WHERE 
    ss.rank_spent <= 10 OR ss.rank_orders <= 10
ORDER BY 
    total_spent DESC, num_orders DESC;
