
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
DailySales AS (
    SELECT 
        dd.d_date_id,
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_profit,
        sd.total_orders,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.hd_income_band_sk,
        cd.hd_buy_potential
    FROM 
        SalesData sd
    JOIN 
        date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        CustomerDetails cd ON 1 = 1 -- Cartesian product for simplicity
)
SELECT 
    ds.d_date_id,
    ds.ws_item_sk,
    ds.total_quantity_sold,
    ds.total_profit,
    ds.total_orders,
    ds.c_first_name,
    ds.c_last_name,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.hd_income_band_sk,
    ds.hd_buy_potential,
    COUNT(*) OVER (PARTITION BY ds.d_date_id ORDER BY ds.total_profit DESC) AS rank_by_profit
FROM 
    DailySales ds
WHERE 
    ds.total_profit > 1000
ORDER BY 
    ds.d_date_id, ds.total_profit DESC
LIMIT 100;
