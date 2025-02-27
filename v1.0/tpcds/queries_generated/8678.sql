
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_ext_sales_price) AS avg_sale_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022
        AND cd.cd_gender = 'F'
        AND cd.cd_education_status IN ('PhD', 'Masters')
    GROUP BY 
        ws.web_site_id
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        sd.web_site_id,
        wd.w_warehouse_id,
        sd.total_sales,
        sd.order_count,
        sd.avg_sale_price,
        wd.total_inventory
    FROM 
        SalesData sd
    JOIN 
        WarehouseData wd ON sd.web_site_id = wd.w_warehouse_id
)
SELECT 
    web_site_id,
    w_warehouse_id,
    total_sales,
    order_count,
    avg_sale_price,
    total_inventory
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
