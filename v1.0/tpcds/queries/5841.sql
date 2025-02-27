
WITH sales_summary AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
top_customers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ss.total_sales) AS total_sales,
        ss.sales_year,
        ss.sales_month
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_first_name = c.c_first_name AND ss.c_last_name = c.c_last_name
    GROUP BY 
        c.c_first_name, c.c_last_name, ss.sales_year, ss.sales_month
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.sales_year,
    tc.sales_month,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders
FROM 
    top_customers tc
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_first_name = tc.c_first_name AND c.c_last_name = tc.c_last_name)
WHERE 
    ws.ws_ship_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = tc.sales_year AND d.d_month_seq = tc.sales_month)
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_sales, tc.sales_year, tc.sales_month
ORDER BY 
    tc.total_sales DESC;
