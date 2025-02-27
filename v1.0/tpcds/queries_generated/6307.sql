
WITH CustomerSales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459587 AND 2459690  -- Selecting a date range of interest
    GROUP BY c.c_customer_sk
),
Demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_income_band_sk
    FROM customer_demographics cd
    JOIN CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
),
IncomeRanges AS (
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN Demographics d ON ib.ib_income_band_sk = d.cd_income_band_sk
)
SELECT d.cd_gender, COUNT(d.cd_demo_sk) AS num_customers, 
       SUM(CASE WHEN cs.total_sales BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound THEN 1 ELSE 0 END) AS customers_within_income_range
FROM Demographics d
JOIN CustomerSales cs ON d.cd_demo_sk = cs.c_customer_sk
JOIN IncomeRanges ir ON d.cd_income_band_sk = ir.ib_income_band_sk
GROUP BY d.cd_gender
ORDER BY num_customers DESC;
