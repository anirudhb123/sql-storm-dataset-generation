
WITH RECURSIVE InventoryCTE AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_warehouse_sk, 
        inv_quantity_on_hand
    FROM inventory 
    WHERE inv_quantity_on_hand > 0
    UNION ALL
    SELECT 
        i.inv_date_sk, 
        i.inv_item_sk, 
        i.inv_warehouse_sk, 
        i.inv_quantity_on_hand - 1
    FROM InventoryCTE i
    WHERE i.inv_quantity_on_hand > 1
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS average_sales_price,
        MAX(ws.ws_sales_price) AS peak_sales_price,
        MIN(ws.ws_sales_price) AS low_sales_price
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_moy = 10
    )
    GROUP BY c.c_customer_id
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        AVG(i.inv_quantity_on_hand) AS avg_inventory
    FROM warehouse w
    LEFT JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT 
    ss.c_customer_id,
    ss.total_orders,
    ss.total_net_profit,
    ss.average_sales_price,
    ws.w_warehouse_id,
    ws.total_inventory,
    ws.avg_inventory,
    CASE 
        WHEN ws.avg_inventory IS NULL THEN 'No Inventory'
        WHEN ws.avg_inventory < 10 THEN 'Low Inventory'
        ELSE 'Sufficient Inventory'
    END AS inventory_status
FROM SalesSummary ss
JOIN WarehouseSummary ws ON ss.total_net_profit > 1000
ORDER BY ss.total_net_profit DESC, ws.total_inventory DESC
LIMIT 100;
