
WITH SalesData AS (
    SELECT 
        w.warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        w.warehouse_id, i.i_item_id, d.d_year
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    sd.warehouse_id,
    sd.i_item_id,
    sd.total_quantity_sold,
    sd.total_net_profit,
    sd.average_sales_price,
    sd.total_orders,
    cd.cd_gender,
    cd.cd_income_band_sk,
    cd.orders_count,
    cd.total_spent
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON cd.orders_count > 0
ORDER BY 
    sd.total_net_profit DESC, sd.total_quantity_sold DESC
LIMIT 100;
