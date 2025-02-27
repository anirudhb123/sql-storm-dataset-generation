
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        EXTRACT(YEAR FROM dd.d_date) AS sales_year,
        EXTRACT(MONTH FROM dd.d_date) AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND dd.d_year >= 2021 
    GROUP BY 
        ws.web_site_id, sales_year, sales_month
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.web_site_id,
    ws.w_warehouse_id,
    ss.total_quantity,
    ss.total_profit,
    ss.total_orders,
    ws.total_inventory,
    (ss.total_profit / NULLIF(ss.total_orders, 0)) AS average_profit_per_order,
    (wa.total_inventory / NULLIF(ss.total_quantity, 0)) AS inventory_turnover_ratio
FROM 
    SalesSummary ss
JOIN 
    WarehouseSummary ws ON ss.web_site_id = ws.w_warehouse_id
ORDER BY 
    ss.sales_year DESC, ss.sales_month DESC, ss.web_site_id;
