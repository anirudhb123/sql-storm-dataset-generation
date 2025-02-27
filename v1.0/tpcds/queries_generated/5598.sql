
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk IN (ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk)
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cw.total_web_sales,
        cw.total_catalog_sales,
        cw.total_store_sales,
        cw.first_purchase_date,
        cw.last_purchase_date
    FROM customer_demographics cd
    JOIN SalesData cw ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
    AVG(cd.total_web_sales) AS avg_web_sales,
    AVG(cd.total_catalog_sales) AS avg_catalog_sales,
    AVG(cd.total_store_sales) AS avg_store_sales,
    COUNT(CASE WHEN cd.last_purchase_date > '2023-06-30' THEN 1 END) AS active_customers_count
FROM CustomerDemographics cd
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY demographic_count DESC;
