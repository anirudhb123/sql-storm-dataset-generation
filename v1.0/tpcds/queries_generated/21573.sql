
WITH RECURSIVE IncomeEligibility AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           cd_education_status, 
           cd_purchase_estimate,
           cd_credit_rating,
           cd_dep_count, 
           cd_dep_employed_count,
           COALESCE(hd_income_band_sk, 0) AS income_band 
    FROM customer_demographics 
    LEFT JOIN household_demographics 
           ON customer_demographics.cd_demo_sk = household_demographics.hd_demo_sk 
    WHERE cd_purchase_estimate > 1000

    UNION ALL

    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           cd_education_status, 
           cd_purchase_estimate,
           cd_credit_rating,
           cd_dep_count,
           cd_dep_employed_count,
           COALESCE(hd_income_band_sk, 0) AS income_band 
    FROM customer_demographics 
    WHERE cd_purchase_estimate IS NOT NULL
)

SELECT ca_state,
       COUNT(DISTINCT c_customer_id) AS total_customers,
       AVG(cd_purchase_estimate) AS avg_purchase_estimate,
       SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
       SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
       COALESCE(SUM(CASE WHEN cd_credit_rating = 'Good' THEN cd_purchase_estimate ELSE 0 END), 0) AS total_good_credit,
       MIN(d_year) AS earliest_year,
       MAX(d_year) AS latest_year
FROM customer_address AS ca
JOIN customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN IncomeEligibility AS ie ON ie.cd_demo_sk = c.c_current_cdemo_sk
JOIN date_dim AS d ON d.d_date_sk = c.c_first_sales_date_sk
LEFT JOIN store_sales AS ss ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN web_sales AS ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ca_state IS NOT NULL
GROUP BY ca_state
HAVING COUNT(DISTINCT c_customer_id) > 10
   AND avg_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
ORDER BY total_customers DESC, ca_state DESC
LIMIT 5
OFFSET 0;

WITH sales_summary AS (
    SELECT ws_sold_date_sk,
           SUM(ws_net_profit) AS total_profit,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_date >= '2023-01-01')
    GROUP BY ws_sold_date_sk
)
SELECT d.d_date, 
       COALESCE(ss.total_profit, 0) AS total_profit,
       COALESCE(ss.total_orders, 0) AS total_orders
FROM date_dim AS d
LEFT JOIN sales_summary AS ss ON d.d_date_sk = ss.ws_sold_date_sk
WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
ORDER BY d.d_date;
