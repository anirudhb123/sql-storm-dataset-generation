
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as rn
    FROM web_sales
    UNION ALL
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_net_paid
    FROM catalog_sales
    WHERE cs_item_sk IN (SELECT ws_item_sk FROM web_sales)
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        RANK() OVER (PARTITION BY cd_income_band_sk ORDER BY cd_purchase_estimate DESC) as rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
TotalSales AS (
    SELECT
        item_sk,
        SUM(ws_quantity) as total_quantity,
        SUM(ws_net_paid) as total_paid
    FROM SalesCTE
    GROUP BY ws_item_sk
)
SELECT
    cd.c_customer_sk,
    SUM(ts.total_quantity) AS total_quantity,
    AVG(ts.total_paid) AS avg_paid,
    MAX(ts.total_paid) AS max_paid,
    COUNT(*) FILTER (WHERE cd.cd_marital_status = 'M') AS married_count,
    COUNT(*) FILTER (WHERE cd.cd_gender = 'F') AS female_count,
    COUNT(*) FILTER (WHERE cd.cd_income_band_sk IS NULL) AS no_income_band_count,
    CASE
        WHEN COUNT(ts.item_sk) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM CustomerDemographics cd
JOIN TotalSales ts ON cd.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk FROM web_sales
    UNION
    SELECT DISTINCT cs_bill_customer_sk FROM catalog_sales
)
GROUP BY cd.c_customer_sk
HAVING SUM(ts.total_quantity) > 10 AND avg_paid > 100
ORDER BY avg_paid DESC
LIMIT 50;
