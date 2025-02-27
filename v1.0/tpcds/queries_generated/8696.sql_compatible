
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        c.c_customer_sk, c.c_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_gender,
        cs.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        DENSE_RANK() OVER (PARTITION BY cs.c_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_gender,
    tc.total_sales,
    tc.total_orders,
    tc.avg_order_value
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.c_gender, tc.total_sales DESC;
