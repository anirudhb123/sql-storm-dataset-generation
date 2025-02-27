
WITH RECURSIVE Address_CTE AS (
    SELECT ca_address_sk, ca_city, ca_county, ca_state, ca_country 
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_county, ca_state, ca_country 
    FROM customer_address a
    JOIN Address_CTE ON a.ca_city = Address_CTE.ca_city 
    AND a.ca_state <> Address_CTE.ca_state
),
Income_Ranges AS (
    SELECT ib_income_band_sk, 
           CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound) AS income_range
    FROM income_band
),
Customer_Demographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, 
           cd_purchase_estimate, 
           RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM customer_demographics
),
Sales_Overview AS (
    SELECT ws_bill_cdemo_sk, 
           SUM(ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 5000 AND 6000
    GROUP BY ws_bill_cdemo_sk
),
Return_Statistics AS (
    SELECT sr_customer_sk, 
           COUNT(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT 
    c.c_customer_id,
    SUM(COALESCE(s.total_net_profit, 0)) AS customer_total_net_profit,
    COALESCE(i.income_range, 'Unknown') AS customer_income_range,
    COUNT(DISTINCT r.total_returns) AS total_returns,
    MAX(c_dp.cd_pdf_ranks) AS best_rank
FROM customer c
LEFT JOIN Sales_Overview s ON c.c_current_cdemo_sk = s.ws_bill_cdemo_sk
LEFT JOIN Income_Ranges i ON c.c_current_cdemo_sk = i.ib_income_band_sk
LEFT JOIN Return_Statistics r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN Customer_Demographics c_dp ON c.c_current_cdemo_sk = c_dp.cd_demo_sk
WHERE (c.c_birth_month + COALESCE(c.c_birth_day, 0)) % 2 = 0
AND EXISTS (
    SELECT 1
    FROM Address_CTE a
    WHERE a.ca_city = c.c_city
    AND a.ca_state != 'NY'
)
GROUP BY c.c_customer_id, i.income_range
HAVING COUNT(DISTINCT r.total_returns) > 0
ORDER BY customer_total_net_profit DESC,
         customer_income_range ASC NULLS LAST;
