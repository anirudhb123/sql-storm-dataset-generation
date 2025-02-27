
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
)
SELECT 
    w.warehouse_id,
    ss.total_sales,
    ss.total_orders
FROM 
    warehouse w
LEFT JOIN 
    sales_summary ss ON w.warehouse_sk = ss.web_site_id
ORDER BY 
    ss.total_sales DESC;
