
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state,
           ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_street_number) AS rn
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_state IS NOT NULL
    UNION ALL
    SELECT ah.ca_address_sk, ah.ca_address_id, ah.ca_street_number, ah.ca_street_name, ah.ca_city, ah.ca_state,
           ROW_NUMBER() OVER (PARTITION BY ah.ca_city, ah.ca_state ORDER BY ah.ca_street_number)
    FROM AddressHierarchy ah
    JOIN customer_address ca ON ca.ca_city = ah.ca_city
    WHERE ca.ca_address_sk > ah.ca_address_sk
),
FilteredDemographics AS (
    SELECT cd_gender, cd_marital_status, cd_income_band_sk,
           COUNT(*) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    WHERE cd_credit_rating IS NOT NULL
    GROUP BY cd_gender, cd_marital_status, cd_income_band_sk
),
MaxIncome as (
    SELECT MAX(ib_upper_bound) as max_income
    FROM income_band
),
SalesSummary AS (
    SELECT ss_sold_date_sk, SUM(ss_net_profit) AS total_net_profit,
           COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM store_sales
    WHERE ss_net_paid > 100
    GROUP BY ss_sold_date_sk
)
SELECT ah.ca_address_id, ah.ca_city, ah.ca_state, fd.customer_count, fd.avg_purchase_estimate,
       ss.total_net_profit, ss.unique_customers,
       CASE 
           WHEN fd.customer_count >= 10 THEN 'High'
           WHEN fd.customer_count BETWEEN 5 AND 9 THEN 'Medium'
           ELSE 'Low' 
       END AS customer_density,
       COALESCE((SELECT MAX(cd_purchase_estimate) 
                 FROM FilteredDemographics 
                 WHERE cd_income_band_sk = (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound = (SELECT max_income FROM MaxIncome))),
                 0) AS top_purchase_est
FROM AddressHierarchy ah
LEFT JOIN FilteredDemographics fd ON ah.ca_address_sk = fd.cd_income_band_sk
LEFT JOIN SalesSummary ss ON ah.ca_address_sk = ss.ss_sold_date_sk
WHERE ah.rn <= 5 AND (ah.ca_state = 'CA' OR ah.ca_state = 'NY')
ORDER BY ah.ca_city, ah.ca_state, customer_density DESC;
