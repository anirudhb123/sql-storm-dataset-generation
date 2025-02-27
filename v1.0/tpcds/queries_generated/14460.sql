
WITH sales_summary AS (
    SELECT 
        ws_web_site_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_web_site_sk
),
inventory_summary AS (
    SELECT 
        inv_warehouse_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_warehouse_sk
)
SELECT 
    w.w_warehouse_id, 
    w.w_warehouse_name, 
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    is.total_quantity
FROM 
    warehouse w
LEFT JOIN 
    sales_summary ss ON w.w_warehouse_sk = ss.ws_web_site_sk
LEFT JOIN 
    inventory_summary is ON w.w_warehouse_sk = is.inv_warehouse_sk
ORDER BY 
    total_sales DESC;
