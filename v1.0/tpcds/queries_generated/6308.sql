
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2022 AND 
        ws.ws_sales_price > 0
    GROUP BY 
        sales_date, ws.web_site_id
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS inventory_available,
        SUM(sd.total_sales) AS total_sales_in_warehouse,
        COUNT(sd.unique_customers) AS num_customers_served
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN 
        SalesData sd ON inv.inv_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_web_site_sk = w.w_warehouse_sk)
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ws.web_site_id,
    ws.total_sales,
    ws.total_orders,
    ws.unique_customers,
    ws.avg_net_profit,
    w.total_sales_in_warehouse,
    w.inventory_available,
    w.num_customers_served
FROM 
    SalesData ws
JOIN 
    WarehouseSales w ON ws.web_site_id = w.w_warehouse_id
ORDER BY 
    ws.total_sales DESC, w.total_sales_in_warehouse DESC
LIMIT 100;
