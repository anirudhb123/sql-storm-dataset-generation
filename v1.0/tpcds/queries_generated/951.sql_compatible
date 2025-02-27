
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_sales, 
        cs.order_count,
        c.c_birth_year
    FROM 
        customer c
    JOIN 
        customer_sales cs ON c.c_customer_id = cs.c_customer_id
    WHERE 
        cs.sales_rank <= 10
),
sales_by_year AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count,
    (SELECT COUNT(DISTINCT ws.ws_order_number) FROM web_sales ws WHERE ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_birth_year = tc.c_birth_year)) AS orders_by_same_birth_year,
    (CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales > 10000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value,
    COALESCE((SELECT sales_amount FROM sales_by_year WHERE d_year = 2023), 0) AS total_sales_2023
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
