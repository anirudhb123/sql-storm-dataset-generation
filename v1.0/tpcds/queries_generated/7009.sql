
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk 
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        total_web_sales, 
        total_catalog_sales, 
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales
    FROM 
        CustomerSales
),
IncomeDistribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales
    FROM 
        SalesSummary s
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    id.customer_count,
    id.avg_sales
FROM 
    IncomeDistribution id
JOIN 
    income_band ib ON id.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
