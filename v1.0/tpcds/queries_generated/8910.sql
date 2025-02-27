
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2022 AND 2023
    GROUP BY ws.web_site_id, d.d_year
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), IncomeStatistics AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS household_count,
        AVG(hd.hd_dep_count) AS avg_dependent_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    r.web_site_id,
    r.total_sales,
    r.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count,
    isd.household_count,
    isd.avg_dependent_count
FROM RankedSales r
JOIN CustomerDemographics cd ON r.web_site_id = cd.cd_demo_sk
JOIN IncomeStatistics isd ON cd.cd_demo_sk = isd.ib_income_band_sk
WHERE r.sales_rank <= 5
ORDER BY r.total_sales DESC;
