
WITH RECURSIVE CustomerReturns AS (
    SELECT cr.returning_customer_sk, SUM(cr.return_quantity) AS total_returned_items
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
RecentSales AS (
    SELECT ws.ship_customer_sk, SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3)
    )
    GROUP BY ws.ship_customer_sk
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           CASE WHEN cd.cd_purchase_estimate IS NULL THEN 0 ELSE cd.cd_purchase_estimate END AS purchase_estimate,
           CASE WHEN h.hd_income_band_sk IS NULL THEN 'Unknown' ELSE ib.ib_lower_bound || '-' || ib.ib_upper_bound END AS income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
),
SalesAndReturns AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.marital_status,
        COALESCE(r.total_returned_items, 0) AS total_returned_items,
        COALESCE(s.total_sales, 0) AS total_sales
    FROM customer c
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.returning_customer_sk
    LEFT JOIN RecentSales s ON c.c_customer_sk = s.ship_customer_sk
),
FinalMetrics AS (
    SELECT *,
           CASE 
              WHEN total_sales > 0 AND total_returned_items > 0 THEN (total_returned_items::decimal / total_sales) * 100
              ELSE NULL
           END AS return_rate
    FROM SalesAndReturns
)
SELECT 
    c_customer_id,
    cd_gender,
    marital_status,
    total_returned_items,
    total_sales,
    return_rate
FROM FinalMetrics
WHERE return_rate IS NOT NULL AND return_rate > 5
ORDER BY return_rate DESC;
