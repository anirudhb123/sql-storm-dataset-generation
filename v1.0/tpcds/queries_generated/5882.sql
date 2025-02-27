
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
), 
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM customer_demographics cd
), 
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        di.cd_purchase_estimate,
        di.cd_credit_rating,
        di.cd_dep_count,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales
    FROM CustomerSales cs
    JOIN DemographicInfo di ON cs.c_customer_sk = di.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.total_sales) AS total_sales_by_demographic,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM SalesSummary ss
JOIN DemographicInfo cd ON ss.cd_gender = cd.cd_gender AND ss.cd_marital_status = cd.cd_marital_status
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY total_sales_by_demographic DESC
LIMIT 10;
