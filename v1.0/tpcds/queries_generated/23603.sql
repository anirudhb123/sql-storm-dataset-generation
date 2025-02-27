
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_zip, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS RN
    FROM customer_address
    WHERE ca_state IS NOT NULL
),
IncomeRanges AS (
    SELECT ib_income_band_sk, 
           CONCAT(COALESCE(CAST(ib_lower_bound AS VARCHAR), '0'), ' - ', COALESCE(CAST(ib_upper_bound AS VARCHAR), 'MAX')) AS income_range
    FROM income_band
),
AggregatedSales AS (
    SELECT ws_bill_cdemo_sk AS customer_sk, 
           SUM(ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY ws_bill_cdemo_sk
)
SELECT ca.ca_city, ca.ca_state, a.income_range, 
       SUM(COALESCE(s.total_spent, 0)) AS total_spent,
       COUNT(DISTINCT CASE WHEN s.order_count > 0 THEN s.customer_sk END) AS unique_customers,
       AVG(CASE WHEN s.total_spent IS NULL THEN 0 ELSE s.total_spent END) AS avg_spent_per_customer 
FROM AddressCTE ca
LEFT JOIN IncomeRanges a ON (a.income_band_sk = (
        SELECT hd_demo_sk 
        FROM household_demographics 
        WHERE hd_demo_sk IN (SELECT c_current_hdemo_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
        LIMIT 1) OR a.income_band_sk IS NULL) 
LEFT JOIN AggregatedSales s ON s.customer_sk = (
    SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk LIMIT 1)
GROUP BY ca.ca_city, ca.ca_state, a.income_range 
HAVING SUM(s.total_spent) > (SELECT AVG(total_spent) FROM AggregatedSales) 
   OR a.income_range IS NOT NULL
ORDER BY ca.ca_state, total_spent DESC NULLS LAST;
