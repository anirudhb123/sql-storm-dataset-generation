
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        c.c_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_gender
),
average_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        c_gender,
        total_sales / NULLIF(order_count, 0) AS average_order_value,
        unique_customers
    FROM 
        sales_summary
)
SELECT 
    a.d_year,
    a.d_month_seq,
    a.c_gender,
    a.average_order_value,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.average_order_value DESC) AS rank_within_year
FROM 
    average_sales AS a
WHERE 
    a.average_order_value > (SELECT AVG(average_order_value) FROM average_sales WHERE d_year = a.d_year)
ORDER BY 
    a.d_year, rank_within_year;
