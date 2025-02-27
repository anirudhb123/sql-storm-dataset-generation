
WITH RECURSIVE top_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        SUM(ws_net_paid) as total_spent
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
    HAVING 
        SUM(ws_net_paid) > 1000
),
date_ranges AS (
    SELECT 
        d.d_date as dt, 
        d.d_year, 
        d.d_month_seq
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2020 AND 2021
),
sales_stats AS (
    SELECT 
        d.y,
        COUNT(ws.ws_order_number) as total_orders,
        SUM(ws.ws_quantity) as total_quantity,
        SUM(ws.ws_net_paid) as total_revenue
    FROM 
        web_sales ws
    JOIN date_ranges d ON ws.ws_sold_date_sk = d.d_year
    GROUP BY 
        d.d_year
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(ct.total_orders, 0) as total_orders,
        coalesce(ct.total_quantity, 0) as total_quantity,
        coalesce(ct.total_revenue, 0) as total_revenue
    FROM 
        top_customers c
    LEFT JOIN sales_stats ct ON c.c_customer_sk = ct.y
)
SELECT 
    cs.c_customer_sk,
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.total_orders,
    cs.total_quantity,
    cs.total_revenue,
    wg.wg_country,
    wg.wg_state
FROM 
    customer_stats cs
LEFT JOIN warehouse wg ON cs.c_customer_sk = wg.w_warehouse_sk
WHERE 
    cs.total_revenue > (SELECT AVG(total_revenue) FROM customer_stats)
ORDER BY 
    cs.total_revenue DESC
LIMIT 10;
