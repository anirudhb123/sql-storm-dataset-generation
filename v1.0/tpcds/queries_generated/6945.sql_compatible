
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS warehouse_quantity,
        SUM(ws.ws_net_profit) AS warehouse_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        ss.web_site_id,
        ss.total_quantity,
        ss.total_profit,
        ws.warehouse_quantity,
        ws.warehouse_profit,
        (ss.total_profit + ws.warehouse_profit) AS combined_profit
    FROM 
        SalesSummary ss
    JOIN 
        WarehouseSales ws ON ss.web_site_id = ws.w_warehouse_id
)
SELECT 
    fr.web_site_id,
    fr.total_quantity,
    fr.total_profit,
    fr.warehouse_quantity,
    fr.warehouse_profit,
    fr.combined_profit
FROM 
    FinalReport fr
ORDER BY 
    fr.combined_profit DESC
LIMIT 10;
