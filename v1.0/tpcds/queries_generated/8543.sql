
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
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
    GROUP BY 
        ws.web_site_id
), WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
), Summary AS (
    SELECT 
        sd.web_site_id,
        wd.w_warehouse_id,
        sd.total_net_profit,
        sd.total_quantity,
        sd.total_orders,
        wd.total_inventory
    FROM 
        SalesData sd
    CROSS JOIN 
        WarehouseData wd
)
SELECT 
    web_site_id,
    w_warehouse_id,
    total_net_profit,
    total_quantity,
    total_orders,
    total_inventory,
    (total_net_profit / NULLIF(total_quantity, 0)) AS avg_profit_per_item,
    (total_net_profit / NULLIF(total_orders, 0)) AS avg_profit_per_order
FROM 
    Summary
ORDER BY 
    total_net_profit DESC
LIMIT 10;
