
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        c.customer_id, 
        cs.total_orders, 
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_orders,
    tc.total_sales,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year >= 1980) AS total_customers,
    (SELECT AVG(total_sales) FROM customer_sales) AS avg_sales
FROM top_customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
