
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq IN (1, 2, 3) -- filtering for the first quarter
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
top_websites AS (
    SELECT 
        web_site_sk, 
        total_orders, 
        total_revenue
    FROM 
        ranked_sales
    WHERE 
        revenue_rank <= 5
)

SELECT 
    w.web_site_id,
    w.web_name,
    t.total_orders,
    t.total_revenue,
    d.d_month_seq AS month,
    d.d_year AS year
FROM 
    top_websites t
JOIN 
    web_site w ON t.web_site_sk = w.web_site_sk
JOIN 
    date_dim d ON t.ws_sold_date_sk = d.d_date_sk
ORDER BY 
    t.total_revenue DESC;
