
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
sales_by_date AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS daily_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    s.daily_sales,
    (tc.total_sales - SUM(s.daily_sales) OVER (ORDER BY s.daily_sales ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) AS sales_change_last_week
FROM 
    top_customers tc
CROSS JOIN 
    sales_by_date s
WHERE 
    s.daily_sales > (SELECT AVG(daily_sales) FROM sales_by_date)
ORDER BY 
    tc.total_sales DESC, s.daily_sales ASC
LIMIT 25;
