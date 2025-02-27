
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
top_web_sites AS (
    SELECT
        web_site_id,
        total_orders,
        total_revenue
    FROM ranked_sales
    WHERE rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ext_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    WHERE ws.sold_date_sk IN (SELECT DISTINCT sold_date_sk FROM web_sales)
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.customer_id,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_sales cs
)
SELECT 
    tws.web_site_id,
    tws.total_orders,
    tws.total_revenue,
    hvc.customer_id,
    hvc.total_spent
FROM top_web_sites tws
JOIN high_value_customers hvc ON tws.total_revenue > hvc.total_spent
ORDER BY tws.total_revenue DESC, hvc.total_spent DESC;
