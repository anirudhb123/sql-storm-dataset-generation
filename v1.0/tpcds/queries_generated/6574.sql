
WITH SalesData AS (
    SELECT 
        w.warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
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
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY 
        w.warehouse_id, i.i_item_id, d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    sd.warehouse_id,
    sd.i_item_id,
    sd.total_quantity_sold,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_sales_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_upper_bound AS income_upper_bound
FROM 
    SalesData sd
JOIN 
    CustomerDemographics cd ON sd.total_orders > 10 
ORDER BY 
    sd.total_net_profit DESC, 
    sd.total_quantity_sold DESC;
