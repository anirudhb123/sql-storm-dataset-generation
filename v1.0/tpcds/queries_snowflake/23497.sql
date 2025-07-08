
WITH RECURSIVE IncomeCategories AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound, 
           ib_upper_bound, 
           CASE 
               WHEN ib_lower_bound IS NOT NULL THEN CAST(ib_lower_bound AS VARCHAR) 
               ELSE 'Unknown' 
           END AS income_range
    FROM income_band
    UNION ALL
    SELECT ib_income_band_sk, 
           ib_lower_bound + 1000, 
           ib_upper_bound + 1000, 
           CASE 
               WHEN ib_lower_bound + 1000 IS NOT NULL THEN CAST(ib_lower_bound + 1000 AS VARCHAR) || ' - ' || CAST(ib_upper_bound + 1000 AS VARCHAR)
               ELSE 'Unknown' 
           END
    FROM IncomeCategories
    WHERE ib_lower_bound + 1000 < 100000
), 
CustomerIncome AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_demo_sk, 
           cd.cd_purchase_estimate, 
           ic.ib_lower_bound, 
           ic.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN IncomeCategories ic ON hd.hd_income_band_sk = ic.ib_income_band_sk
), 
SalesSummary AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
RankedCustomers AS (
    SELECT ci.c_customer_id, 
           ci.cd_demo_sk, 
           ci.cd_purchase_estimate, 
           ss.total_quantity, 
           ss.total_sales, 
           DENSE_RANK() OVER (PARTITION BY ci.cd_demo_sk ORDER BY ss.total_sales DESC) AS sales_rank
    FROM CustomerIncome ci
    LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT r.c_customer_id, 
       r.cd_demo_sk, 
       r.cd_purchase_estimate, 
       r.total_quantity, 
       r.total_sales, 
       r.sales_rank,
       COALESCE(NULLIF(r.total_sales, 0), 1 / NULLIF(r.total_quantity, 0), 0) AS adjusted_sales_value
FROM RankedCustomers r
WHERE r.sales_rank <= 10 
  AND (r.total_sales IS NOT NULL OR r.total_quantity IS NOT NULL) 
  AND r.cd_purchase_estimate IN (SELECT cd_purchase_estimate FROM customer_demographics WHERE cd_gender = 'F' AND cd_marital_status = 'M')
ORDER BY r.cd_demo_sk, r.sales_rank;
