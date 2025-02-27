
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_net_profit ELSE 0 END) AS total_sales,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, c.c_gender
),
total_sales AS (
    SELECT 
        d_year, 
        SUM(total_sales) AS year_total_sales 
    FROM 
        sales_summary 
    GROUP BY 
        d_year
)
SELECT 
    s.d_year, 
    s.c_gender, 
    s.total_sales,
    ROUND(s.total_sales * 100.0 / t.year_total_sales, 2) AS sales_percentage
FROM 
    sales_summary s
JOIN 
    total_sales t ON s.d_year = t.d_year
ORDER BY 
    s.d_year, s.c_gender;
