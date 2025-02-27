
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
AverageSales AS (
    SELECT 
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        CustomerSales
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_by_demo,
        SUM(ws.total_web_sales) AS total_web_sales_by_demo,
        SUM(ss.total_store_sales) AS total_store_sales_by_demo
    FROM 
        CustomerSales cs
    INNER JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    INNER JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    ds.cd_gender,
    ds.hd_income_band_sk,
    ds.total_catalog_sales_by_demo,
    ds.total_web_sales_by_demo,
    ds.total_store_sales_by_demo,
    as.avg_web_sales,
    as.avg_catalog_sales,
    as.avg_store_sales
FROM 
    DemographicSales ds, AverageSales as
WHERE 
    ds.total_catalog_sales_by_demo > (SELECT avg_catalog_sales FROM AverageSales) 
    OR ds.total_web_sales_by_demo > (SELECT avg_web_sales FROM AverageSales)
ORDER BY 
    ds.cd_gender, ds.hd_income_band_sk;
