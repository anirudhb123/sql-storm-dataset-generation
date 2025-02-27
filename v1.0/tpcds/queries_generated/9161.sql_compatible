
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (6, 7) 
    GROUP BY 
        ws.web_site_id
),
top_sales AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        rank_sales <= 5
)
SELECT 
    w.web_site_id,
    w.web_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.order_count, 0) AS order_count,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    web_site w
LEFT JOIN 
    top_sales ts ON w.web_site_id = ts.web_site_id
LEFT JOIN 
    web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    w.web_site_id, w.web_name
ORDER BY 
    total_sales DESC;
