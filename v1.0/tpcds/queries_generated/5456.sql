
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws_order_number, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws_order_number
),
top_sales AS (
    SELECT 
        web_site_sk, 
        total_sales, 
        unique_customers, 
        total_quantity 
    FROM 
        ranked_sales 
    WHERE 
        sales_rank <= 10
)
SELECT 
    w.web_name,
    ts.total_sales,
    ts.unique_customers,
    ts.total_quantity,
    w.web_city,
    w.web_state,
    w.web_country
FROM 
    top_sales ts
JOIN 
    web_site w ON ts.web_site_sk = w.web_site_sk
ORDER BY 
    ts.total_sales DESC;
