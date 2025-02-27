
WITH RECURSIVE IncomeRanges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound 
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, 
           ib.ib_lower_bound + 1000,
           ib.ib_upper_bound + 1000
    FROM income_band ib 
    JOIN IncomeRanges ir ON ir.ib_income_band_sk = ib.ib_income_band_sk 
    WHERE ib.ib_lower_bound + 1000 <= 100000
),
CustomerData AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           ARRAY_AGG(DISTINCT ca.ca_city) AS cities, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_first_name IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
SalesSummary AS (
    SELECT 
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales, 
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
),
FilteredCustomers AS (
    SELECT
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ir.ib_income_band_sk,
        ir.ib_lower_bound,
        ir.ib_upper_bound,
        COALESCE(ss.total_web_sales, 0) + COALESCE(ss.total_catalog_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_sales
    FROM CustomerData cd
    LEFT JOIN SalesSummary ss ON cd.rn = 1
    LEFT JOIN IncomeRanges ir ON cd.cd_purchase_estimate BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
)
SELECT 
    fc.c_first_name, 
    fc.c_last_name, 
    fc.cd_gender, 
    fc.cd_marital_status, 
    fc.ib_lower_bound || ' - ' || fc.ib_upper_bound AS income_range,
    SUM(fc.total_sales) AS aggregated_sales
FROM FilteredCustomers fc
WHERE fc.ib_income_band_sk IS NOT NULL
GROUP BY fc.c_first_name, fc.c_last_name, fc.cd_gender, fc.cd_marital_status, fc.ib_lower_bound, fc.ib_upper_bound
HAVING SUM(fc.total_sales) > (SELECT AVG(total_sales) FROM FilteredCustomers)
ORDER BY aggregated_sales DESC
LIMIT 10;
