
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
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
        cd.cd_marital_status,
        SUM(ss.total_revenue) AS segment_revenue,
        SUM(ss.total_orders) AS segment_orders,
        SUM(ss.unique_customers) AS segment_customers
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.web_site_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.segment_revenue,
    cs.segment_orders,
    cs.segment_customers,
    ws.w_warehouse_id,
    ws.total_items,
    ws.total_inventory
FROM 
    customer_segment cs
JOIN 
    warehouse_summary ws ON cs.segment_revenue > 100000
ORDER BY 
    cs.segment_revenue DESC, ws.total_inventory DESC
LIMIT 10;
