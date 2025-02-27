
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 
DemographicsAnalysis AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sd.total_net_profit) AS net_profit
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesData sd ON sd.unique_customers = COUNT(DISTINCT c.c_customer_sk)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), 
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.customer_count,
    da.net_profit,
    wp.w_warehouse_id,
    wp.total_inventory_value,
    wp.order_count
FROM 
    DemographicsAnalysis da
JOIN 
    WarehousePerformance wp ON da.customer_count > 0
ORDER BY 
    da.net_profit DESC, wp.order_count DESC;
