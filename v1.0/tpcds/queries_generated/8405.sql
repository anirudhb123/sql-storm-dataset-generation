
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimates
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.web_site_id,
    ss.total_quantity,
    ss.total_profit,
    ss.total_orders,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_purchase_estimates,
    ws.w_warehouse_id,
    ws.total_items,
    ws.total_quantity_on_hand
FROM 
    sales_summary ss
CROSS JOIN 
    demographics_summary ds
CROSS JOIN 
    warehouse_summary ws
ORDER BY 
    ss.total_profit DESC, ds.customer_count DESC, ws.total_quantity_on_hand DESC
LIMIT 100;
