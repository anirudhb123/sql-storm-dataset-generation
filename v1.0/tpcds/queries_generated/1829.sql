
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_net_paid_inc_ship_tax) AS average_order_value
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS demographic_count
    FROM 
        household_demographics hd 
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders,
    sd.unique_customers,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No Data'
        ELSE CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status)
    END AS customer_profile,
    ib.demographic_count
FROM 
    SalesData sd
LEFT JOIN 
    CustomerDemographics cd ON cd.customer_count > 0
LEFT JOIN 
    IncomeBand ib ON ib.demographic_count > 10
ORDER BY 
    sd.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
