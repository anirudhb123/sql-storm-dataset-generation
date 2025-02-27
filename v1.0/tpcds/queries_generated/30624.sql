
WITH RECURSIVE IncomeDetails AS (
    SELECT
        hd_demo_sk,
        ib_income_band_sk,
        hd_buy_potential,
        hd_dep_count,
        hd_vehicle_count,
        1 AS level
    FROM household_demographics
    WHERE ib_income_band_sk IS NOT NULL

    UNION ALL

    SELECT
        hd.demo_sk,
        hd.ib_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        id.level + 1
    FROM household_demographics hd
    JOIN IncomeDetails id ON hd.ib_income_band_sk = id.ib_income_band_sk
    WHERE id.level < 3
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
    )
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(sd.ws_sales_price) AS total_sales,
        COUNT(sd.ws_order_number) AS total_orders
    FROM customer c
    JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cs.total_sales,
        cs.total_orders,
        CONCAT('Customer ', cd.c_customer_sk, ' has total sales of $', COALESCE(cs.total_sales, 0)) AS sales_summary
    FROM CustomerDemographics cd
    LEFT JOIN CustomerSales cs ON cd.c_customer_sk = cs.c_customer_sk
)
SELECT 
    fr.*,
    id.hd_buy_potential,
    id.hd_dep_count,
    id.hd_vehicle_count
FROM FinalReport fr
LEFT JOIN IncomeDetails id ON fr.c_customer_sk = id.hd_demo_sk
WHERE id.level = 1 AND fr.total_sales > 1000
ORDER BY fr.total_sales DESC
LIMIT 50;
