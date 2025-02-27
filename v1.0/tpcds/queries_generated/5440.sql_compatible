
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2021
    GROUP BY w.w_warehouse_name, d.d_year
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_net_profit) AS demographic_net_profit,
        AVG(sd.total_orders) AS avg_orders_per_demographic
    FROM SalesData sd
    JOIN customer c ON sd.w_warehouse_name = c.c_customer_id
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        (ib.ib_upper_bound + ib.ib_lower_bound) / 2 AS avg_income
    FROM income_band ib
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    SUM(d.demographic_net_profit) AS total_demographic_profit,
    AVG(ib.avg_income) AS average_income,
    COUNT(DISTINCT d.cd_gender || d.cd_marital_status) AS unique_demographics
FROM Demographics d
JOIN IncomeBand ib ON d.demographic_net_profit > ib.ib_lower_bound AND d.demographic_net_profit <= ib.ib_upper_bound
GROUP BY d.cd_gender, d.cd_marital_status
ORDER BY total_demographic_profit DESC
LIMIT 10;
