
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, d.d_year, ws.ws_sold_date_sk
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    wd.w_warehouse_id,
    sd.d_year,
    sd.total_profit,
    sd.total_orders,
    sd.avg_sales_price,
    wd.total_inventory
FROM 
    SalesData sd
JOIN 
    WarehouseData wd ON sd.web_site_id = wd.w_warehouse_id
ORDER BY 
    sd.d_year DESC, sd.total_profit DESC
LIMIT 100;
