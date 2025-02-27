
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 3000
    GROUP BY 
        ws.web_site_id
)
SELECT 
    w.web_site_id,
    w.web_name,
    ss.total_sales,
    ss.number_of_orders
FROM 
    web_site w
LEFT JOIN 
    sales_summary ss ON w.web_site_id = ss.web_site_id
ORDER BY 
    ss.total_sales DESC
LIMIT 
    100;
