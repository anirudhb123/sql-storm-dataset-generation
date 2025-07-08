
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sum(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
sales_analysis AS (
    SELECT 
        t.c_customer_sk,
        t.c_first_name,
        t.c_last_name,
        t.total_sales,
        t.total_orders,
        d.d_year,
        d.d_quarter_seq,
        d.d_month_seq
    FROM 
        top_customers t
    JOIN 
        date_dim d ON d.d_date_sk IN (SELECT ws_sold_date_sk FROM web_sales WHERE ws_bill_customer_sk = t.c_customer_sk)
    WHERE 
        t.sales_rank <= 10
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.total_sales,
    sa.total_orders,
    sa.d_year,
    sa.d_quarter_seq,
    sa.d_month_seq,
    AVG(sa.total_sales) OVER (PARTITION BY sa.d_year, sa.d_quarter_seq) AS avg_sales_per_quarter
FROM 
    sales_analysis sa
ORDER BY 
    sa.total_sales DESC;
