
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_last_name, c.c_first_name
),
top_customers AS (
    SELECT 
        customer_sk,
        c_last_name,
        c_first_name,
        total_sales
    FROM 
        sales_hierarchy
    WHERE 
        sales_rank <= 10
),
sales_dates AS (
    SELECT 
        d.d_date,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
avg_daily_sales AS (
    SELECT 
        AVG(sales_amount) AS avg_sales
    FROM 
        sales_dates
)
SELECT 
    tc.c_last_name || ', ' || tc.c_first_name AS customer_name,
    tc.total_sales,
    sd.d_date,
    sd.order_count,
    sd.sales_amount,
    CASE 
        WHEN sd.sales_amount > ads.avg_sales THEN 'Above Average'
        WHEN sd.sales_amount < ads.avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_comparison
FROM 
    top_customers tc
CROSS JOIN 
    sales_dates sd
CROSS JOIN 
    avg_daily_sales ads
WHERE 
    sd.d_date IS NOT NULL
ORDER BY 
    tc.total_sales DESC, sd.sales_amount DESC;
