
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (6, 7, 8) -- Summer months
        AND cd.cd_gender = 'F' -- Female customers
    GROUP BY 
        ws.web_site_id
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_sales_price,
    sd.unique_customers,
    ws.w_warehouse_id,
    ws.distinct_items,
    ws.total_quantity
FROM 
    SalesData sd
JOIN 
    WarehouseStats ws ON ws.w_warehouse_id = (SELECT w_warehouse_id FROM warehouse ORDER BY w_warehouse_id LIMIT 1) -- Example for a specific warehouse
WHERE 
    sd.total_net_profit > 0
ORDER BY 
    sd.total_net_profit DESC;
