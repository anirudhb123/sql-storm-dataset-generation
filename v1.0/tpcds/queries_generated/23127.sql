
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ss_customer_sk,
        ws_item_sk,
        total_quantity,
        ROUND(total_net_paid / NULLIF(total_quantity, 0), 2) AS avg_net_paid
    FROM SalesSummary
    WHERE rn <= 5
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cp.promo_name,
        COALESCE(SUM(ts.total_quantity), 0) AS quantity_by_gender
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN TopSales ts ON c.c_customer_sk = ts.ws_bill_customer_sk
    LEFT JOIN promotion cp ON ts.ws_item_sk = cp.p_item_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cp.promo_name
),
RevenueByGender AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(quantity_by_gender) AS total_quantity,
        (SUM(quantity_by_gender) * 1.0 / NULLIF(SUM(NULLIF(quantity_by_gender, 0)), 0)) AS gender_ratio
    FROM CustomerDemographics
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    rg.cd_gender,
    rg.cd_marital_status,
    rg.total_quantity,
    rg.gender_ratio,
    CASE
        WHEN rg.gender_ratio IS NULL THEN 'Not applicable'
        WHEN rg.gender_ratio > 1 THEN 'More Purchases'
        WHEN rg.gender_ratio < 1 THEN 'Fewer Purchases'
        ELSE 'Equal Purchases'
    END AS purchase_trend
FROM RevenueByGender rg
FULL OUTER JOIN customer_demographics cd 
ON rg.cd_gender = cd.cd_gender AND rg.cd_marital_status = cd.cd_marital_status
WHERE rg.total_quantity > 100 OR cd.cd_marital_status IS NULL
ORDER BY rg.cd_gender, rg.cd_marital_status;
