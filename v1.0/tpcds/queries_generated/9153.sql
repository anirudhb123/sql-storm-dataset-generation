
WITH SalesData AS (
    SELECT 
        wd.w_warehouse_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM 
        warehouse wd
    LEFT JOIN web_sales ws ON wd.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN catalog_sales cs ON wd.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN store_sales ss ON wd.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        wd.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.total_sales) AS total_sales_by_demographics,
    SUM(sd.web_sales_count) AS total_web_sales,
    SUM(sd.catalog_sales_count) AS total_catalog_sales,
    SUM(sd.store_sales_count) AS total_store_sales
FROM 
    SalesData sd
JOIN 
    CustomerDemographics cd ON random() < 0.5  -- Simulate demographic matching
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_by_demographics DESC
LIMIT 10;
