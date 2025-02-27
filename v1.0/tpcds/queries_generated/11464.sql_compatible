
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    warehouse w
LEFT JOIN 
    sales_summary ss ON w.warehouse_sk = ss.web_site_sk
ORDER BY 
    total_sales DESC;
