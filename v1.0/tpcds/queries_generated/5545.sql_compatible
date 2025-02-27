
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        c.c_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_gender
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS customer_total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        customer_total_sales DESC
    LIMIT 10
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.c_gender,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sales_price,
    tc.c_customer_id,
    tc.customer_total_sales
FROM 
    sales_summary ss
JOIN 
    top_customers tc ON ss.total_sales > 10000
ORDER BY 
    ss.d_year, ss.d_month_seq, ss.c_gender;
