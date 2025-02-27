
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    JOIN 
        warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalData AS (
    SELECT 
        sd.web_site_id,
        wd.w_warehouse_id,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_net_profit,
        wd.total_inventory
    FROM 
        SalesData AS sd
    CROSS JOIN 
        WarehouseData AS wd
)
SELECT 
    web_site_id,
    w_warehouse_id,
    total_quantity,
    total_sales,
    avg_net_profit,
    total_inventory,
    (total_sales / NULLIF(total_quantity, 0)) AS avg_sales_per_item,
    CASE 
        WHEN total_inventory >= 100 THEN 'High Stock'
        ELSE 'Low Stock' 
    END AS stock_status
FROM 
    FinalData
ORDER BY 
    total_sales DESC
LIMIT 10;
