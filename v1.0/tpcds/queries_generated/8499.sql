
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_id,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.web_site_id,
    w.warehouse_id,
    ss.d_year,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_order_value,
    wi.avg_inventory
FROM 
    sales_summary ss
JOIN 
    warehouse_info wi ON ss.web_site_id = wi.warehouse_id
ORDER BY 
    ss.d_year, ss.total_net_profit DESC;
