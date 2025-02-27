
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
SalesByDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
)
SELECT
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    sd.total_web_sales,
    sd.total_catalog_sales,
    sd.total_store_sales,
    (sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales) AS total_sales,
    (sd.total_web_sales / NULLIF((sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales), 0)) * 100 AS web_sales_percentage,
    (sd.total_catalog_sales / NULLIF((sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales), 0)) * 100 AS catalog_sales_percentage,
    (sd.total_store_sales / NULLIF((sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales), 0)) * 100 AS store_sales_percentage
FROM
    SalesByDemographics sd
ORDER BY
    total_sales DESC
LIMIT 10;
