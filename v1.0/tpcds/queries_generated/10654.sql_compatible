
WITH sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        ws.web_site_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.sold_date_sk, ws.web_site_sk
)
SELECT 
    dd.d_month_seq, 
    dd.d_year, 
    SUM(ss.total_sales) AS monthly_sales, 
    SUM(ss.total_orders) AS monthly_orders
FROM 
    sales_summary ss
JOIN 
    date_dim dd ON ss.sold_date_sk = dd.d_date_sk
GROUP BY 
    dd.d_month_seq, dd.d_year
ORDER BY 
    dd.d_year, dd.d_month_seq;
