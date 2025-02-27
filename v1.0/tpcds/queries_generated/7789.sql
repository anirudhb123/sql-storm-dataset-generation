
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
InventoryData AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    JOIN 
        warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE 
        w.w_state = 'CA'
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    sd.web_site_sk,
    id.inv_warehouse_sk,
    sd.total_sales,
    sd.order_count,
    sd.avg_net_profit,
    id.total_inventory
FROM 
    SalesData AS sd
JOIN 
    InventoryData AS id ON sd.web_site_sk = id.inv_warehouse_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
