
WITH ItemSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        id.web_site_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ib_income_band_sk,
        id.total_sales,
        id.order_count,
        id.avg_profit,
        id.unique_customers
    FROM 
        ItemSales id
    LEFT JOIN 
        CustomerDemographics cd ON id.web_site_id IN (
            SELECT ws.web_site_id 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk IN (
                SELECT c.c_customer_sk 
                FROM customer c
            )
        )
)
SELECT 
    ss.web_site_id,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.ib_income_band_sk,
    ss.total_sales,
    ss.order_count,
    ss.avg_profit,
    ss.unique_customers
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
