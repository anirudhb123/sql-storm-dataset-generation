
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        w.w_warehouse_id, d.d_year
),
customer_segment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
inventory_details AS (
    SELECT 
        i.i_item_id, 
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    JOIN 
        item it ON i.inv_item_sk = it.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ss.w_warehouse_id,
    ss.d_year,
    ss.total_quantity,
    ss.total_sales,
    cs.customer_count,
    id.total_inventory
FROM 
    sales_summary ss
JOIN 
    customer_segment cs ON cs.customer_count > 0
JOIN 
    inventory_details id ON id.total_inventory > 0
ORDER BY 
    ss.d_year DESC, ss.total_sales DESC
LIMIT 100;
