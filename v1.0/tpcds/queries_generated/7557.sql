
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (ORDER BY c.total_sales DESC) AS rank
    FROM 
        customer_sales AS c
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    d.d_month AS sales_month
FROM 
    top_customers AS tc
JOIN 
    date_dim AS d ON d.d_year = 2023
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales DESC;
