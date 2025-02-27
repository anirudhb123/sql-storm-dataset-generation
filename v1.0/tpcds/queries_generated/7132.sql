
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_moy IN (11, 12) -- November and December
    GROUP BY 
        w.warehouse_id
),
customer_summary AS (
    SELECT 
        cd.gender,
        cd.education_status,
        COUNT(DISTINCT c.customer_sk) AS customer_count,
        SUM(s.total_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary s ON s.warehouse_id IN (
            SELECT 
                w.warehouse_id 
            FROM 
                warehouse w
            JOIN 
                web_sales ws ON ws.warehouse_sk = w.warehouse_sk
        ) 
    GROUP BY 
        cd.gender, cd.education_status
),
inventory_summary AS (
    SELECT 
        i.item_id,
        SUM(inv.quantity_on_hand) AS total_inventory,
        MIN(i.current_price) AS min_price,
        MAX(i.current_price) AS max_price
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.item_id
)
SELECT 
    cs.gender,
    cs.education_status,
    cs.customer_count,
    cs.total_profit,
    is.total_inventory,
    is.min_price,
    is.max_price
FROM 
    customer_summary cs
JOIN 
    inventory_summary is ON cs.customer_count > 1000 -- Only include customers with significant orders
ORDER BY 
    cs.total_profit DESC
LIMIT 100;
