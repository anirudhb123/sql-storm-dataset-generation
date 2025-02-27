
WITH CustomerIncome AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, h.hd_income_band_sk
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales, 0) AS total_sales,
    SUM(ci.customer_count) AS total_customers
FROM CustomerIncome ci
JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN SalesData sd ON ci.cd_demo_sk = sd.ws_item_sk
GROUP BY 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
ORDER BY 
    ci.cd_gender, 
    ci.cd_marital_status;
