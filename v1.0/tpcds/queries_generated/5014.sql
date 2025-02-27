
WITH sales_summary AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.s_ship_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_web_site_sk, ws.s_ship_date_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(inv.total_inventory, 0) AS total_inventory
    FROM 
        warehouse w
    LEFT JOIN 
        sales_summary ss ON w.w_warehouse_sk = ss.ws_web_site_sk
    LEFT JOIN 
        inventory_summary inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.total_sales,
    w.total_inventory,
    (CASE WHEN w.total_inventory > 0 THEN w.total_sales / w.total_inventory ELSE 0 END) AS sales_per_inventory
FROM 
    warehouse_summary w
WHERE 
    w.total_sales > 0
ORDER BY 
    w.total_sales DESC;
