
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_segment AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_processed
    FROM 
        inventory i 
    JOIN 
        web_sales ws ON i.inv_item_sk = ws.ws_item_sk
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_profit,
    cs.cd_gender,
    cs.total_customers,
    wp.w_warehouse_id,
    wp.total_inventory,
    wp.total_orders_processed
FROM 
    sales_data sd
JOIN 
    customer_segment cs ON 1=1
JOIN 
    warehouse_performance wp ON 1=1
ORDER BY 
    sd.total_sales DESC, 
    cs.total_customers DESC, 
    wp.total_inventory DESC
LIMIT 100;
