
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        d.d_date AS sale_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.web_site_sk, ws.web_name, d.d_date
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
HighValueSales AS (
    SELECT 
        s.web_site_sk,
        SUM(s.total_net_profit) AS total_net_profit
    FROM SalesData s
    WHERE s.total_net_profit > 10000
    GROUP BY s.web_site_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(hv.total_net_profit, 0) AS high_value_net_profit,
    AVG(s.total_sales) AS avg_sales
FROM CustomerDemographics cd
LEFT JOIN HighValueSales hv ON cd.cd_demo_sk = hv.web_site_sk
JOIN SalesData s ON s.web_site_sk = hv.web_site_sk
GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hv.total_net_profit
HAVING AVG(s.total_sales) > 5
ORDER BY high_value_net_profit DESC, cd.cd_gender;
