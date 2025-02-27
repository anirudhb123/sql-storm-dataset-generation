
WITH RECURSIVE IncomeBandCTE AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           ROW_NUMBER() OVER (ORDER BY ib_income_band_sk) AS rn
    FROM income_band
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        MAX(ws.ws_ship_date_sk) AS last_purchase_date
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
DemographicSales AS (
    SELECT 
        cs.c_customer_sk,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_sales,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales
    FROM customer c
    LEFT JOIN store_sales ss ON cs.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cs.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(DISTINCT ss.total_sales) AS total_sales_value,
    COUNT(DISTINCT ss.c_customer_sk) OVER (PARTITION BY cd.cd_gender) AS total_customers_by_gender,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.total_sales) DESC) AS sales_rank
FROM SalesSummary ss
JOIN CustomerDemographics cd ON ss.c_customer_sk = cd.cd_demo_sk
JOIN IncomeBandCTE ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ss.total_quantity > 0
GROUP BY 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ib.ib_lower_bound, 
    ib.ib_upper_bound
HAVING SUM(DISTINCT ss.total_sales) > 1000
ORDER BY sales_rank;
