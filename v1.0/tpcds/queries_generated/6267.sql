
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
top_web_sites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        number_of_orders 
    FROM 
        ranked_sales 
    WHERE 
        rank <= 10
)
SELECT 
    w.web_site_id,
    w.web_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.number_of_orders, 0) AS number_of_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    web_site w
LEFT JOIN 
    top_web_sites ts ON w.web_site_id = ts.web_site_id
LEFT JOIN 
    web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
WHERE 
    ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    w.web_site_id, w.web_name, ts.total_sales, ts.number_of_orders
ORDER BY 
    total_sales DESC;
