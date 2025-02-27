
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_ext_tax) AS avg_tax,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items
    FROM 
        warehouse AS w
    JOIN 
        inventory AS i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.web_site_id,
    ss.total_net_profit,
    ss.total_orders,
    ss.unique_customers,
    ss.avg_tax,
    ss.total_quantity,
    ws.w_warehouse_id,
    ws.total_inventory,
    ws.distinct_items
FROM 
    sales_summary AS ss
JOIN 
    warehouse_summary AS ws ON ss.web_site_id = ws.w_warehouse_id
ORDER BY 
    ss.total_net_profit DESC, ss.total_orders DESC
LIMIT 10;
