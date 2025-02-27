
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, d.d_quarter_seq
),
ranked_sales AS (
    SELECT 
        customer_sk, 
        c_first_name, 
        c_last_name, 
        total_sales,
        order_count,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    d_year,
    d_month_seq,
    COUNT(CASE WHEN sales_rank = 1 THEN 1 END) AS top_customers_count,
    AVG(total_sales) AS avg_top_customer_sales
FROM 
    ranked_sales
GROUP BY 
    d_year, d_month_seq
ORDER BY 
    d_year, d_month_seq;
