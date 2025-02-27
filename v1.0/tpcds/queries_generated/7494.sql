
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM web_sales AS ws
    JOIN date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id, ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_net_profit) AS demographics_net_profit,
        SUM(sd.total_orders) AS demographics_total_orders,
        AVG(sd.avg_quantity_per_order) AS demographics_avg_quantity
    FROM SalesData AS sd
    JOIN customer AS c ON sd.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders,
        avg_quantity_per_order,
        RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM SalesData
)
SELECT 
    w.web_site_id,
    w.warehouse_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(wp.demographics_net_profit) AS total_demographics_net_profit,
    AVG(wp.demographics_avg_quantity) AS overall_avg_quantity
FROM TopWebSites AS w
JOIN CustomerDemographics AS cd ON w.web_site_id = cd.web_site_id
LEFT JOIN (
    SELECT 
        web_site_id,
        SUM(demographics_net_profit) AS demographics_net_profit,
        AVG(demographics_avg_quantity) AS demographics_avg_quantity
    FROM CustomerDemographics
    GROUP BY web_site_id
) AS wp ON w.web_site_id = wp.web_site_id
WHERE w.profit_rank <= 10
GROUP BY w.web_site_id, w.warehouse_name, cd.cd_gender, cd.cd_marital_status
ORDER BY total_demographics_net_profit DESC;
