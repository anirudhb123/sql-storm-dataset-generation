
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DATEADD(day, -7, d.d_date) AS sales_week
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= '2023-01-01'
    GROUP BY 
        ws.ws_item_sk, DATEADD(day, -7, d.d_date)
),
DemographicData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Metrics AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.ib_income_band_sk,
        dd.hd_buy_potential
    FROM 
        SalesData sd
    JOIN 
        DemographicData dd ON sd.ws_item_sk = dd.cd_demo_sk
)
SELECT 
    m.ws_item_sk,
    m.total_quantity,
    m.total_sales,
    m.cd_gender,
    m.cd_marital_status,
    m.ib_income_band_sk,
    m.hd_buy_potential,
    COUNT(m.ws_item_sk) OVER (PARTITION BY m.ib_income_band_sk ORDER BY m.total_sales DESC) AS sales_rank
FROM 
    Metrics m
WHERE 
    m.total_sales > 1000
ORDER BY 
    m.total_sales DESC, m.ws_item_sk;
