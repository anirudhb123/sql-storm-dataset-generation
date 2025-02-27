
WITH RECURSIVE IncomeRanges AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound, 
           ib_upper_bound 
    FROM income_band 
    UNION ALL 
    SELECT ib.ib_income_band_sk, 
           ib.ib_lower_bound, 
           ib.ib_upper_bound 
    FROM income_band ib
    JOIN IncomeRanges ir ON ib.ib_lower_bound <= ir.ib_upper_bound AND ir.ib_lower_bound <= ib.ib_upper_bound
),
CustomerStats AS (
    SELECT c_customer_sk,
           CASE 
               WHEN cd_gender = 'M' THEN 'Male'
               WHEN cd_gender = 'F' THEN 'Female'
               ELSE 'Other'
           END AS gender,
           COUNT(DISTINCT hd_demo_sk) AS households,
           SUM(cd_purchase_estimate) AS total_estimated_purchase
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY c_customer_sk, cd_gender
),
ReturnsAnalysis AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
SalesWithReturns AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        COALESCE(SUM(ra.total_return_quantity), 0) AS total_return_quantity,
        (SUM(ws.ws_sales_price) - COALESCE(SUM(ra.total_return_amount), 0)) AS net_sales
    FROM web_sales ws
    LEFT JOIN ReturnsAnalysis ra ON ws.ws_sold_date_sk = ra.sr_returned_date_sk
    GROUP BY ws.ws_sold_date_sk
),
TopCustomers AS (
    SELECT customer_stats.c_customer_sk,
           customer_stats.gender,
           ROW_NUMBER() OVER (PARTITION BY customer_stats.gender ORDER BY customer_stats.total_estimated_purchase DESC) as rank
    FROM CustomerStats customer_stats
)
SELECT 
    ws.d_date AS sale_date,
    SUM(sales.total_sales_quantity) AS total_sales, 
    SUM(sales.net_sales) AS total_net_sales,
    MAX(tc.gender) as prominent_gender,
    AVG(CASE WHEN protected_income_band.ib_income_band_sk IS NOT NULL THEN NULL ELSE total_estimated_purchase END) as average_purchase_excluding_income
FROM SalesWithReturns sales
JOIN date_dim ws ON ws.d_date_sk = sales.ws_sold_date_sk
LEFT JOIN TopCustomers tc ON tc.c_customer_sk IN (
    SELECT c.c_customer_sk FROM customer c WHERE c.c_birth_year IS NULL
), 
protected_income_band ON protected_income_band.ib_income_band_sk = (
    SELECT MIN(ib.ib_income_band_sk) FROM IncomeRanges ib WHERE ib.ib_upper_bound >= sales.total_net_sales
)
GROUP BY ws.d_date
HAVING total_sales IS NOT NULL AND (average_purchase_excluding_income IS NOT NULL OR prominent_gender IS NOT NULL)
ORDER BY sale_date DESC;
