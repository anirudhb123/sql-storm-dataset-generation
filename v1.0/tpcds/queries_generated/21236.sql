
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_country = ah.ca_country
    WHERE ah.level < 5
),
IncomeStats AS (
    SELECT ib_income_band_sk, 
           COUNT(DISTINCT cd_demo_sk) AS demographic_count, 
           AVG(cd_purchase_estimate) AS average_income_estimate
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib_income_band_sk
),
TopCustomer AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_net_profit DESC
    LIMIT 10
)
SELECT ah.ca_city, 
       ah.ca_state, 
       ah.ca_country, 
       COUNT(DISTINCT tc.c_customer_sk) AS customer_count, 
       COALESCE(SUM(is.average_income_estimate), 0) AS total_income_estimate,
       STRING_AGG(DISTINCT tc.c_first_name || ' ' || tc.c_last_name, ', ') AS top_customers,
       CASE 
           WHEN COUNT(tc.c_customer_sk) > 0 THEN 'Active' 
           ELSE 'Inactive' 
       END AS customer_status
FROM AddressHierarchy ah
LEFT JOIN TopCustomer tc ON ah.ca_city = tc.c_middle_name AND ah.ca_state = tc.c_last_name
LEFT JOIN IncomeStats is ON ah.ca_country = (CASE 
                                            WHEN is.ib_income_band_sk IS NULL THEN ah.ca_country 
                                            ELSE 'Unknown' 
                                            END)
WHERE ah.level = 0
GROUP BY ah.ca_city, ah.ca_state, ah.ca_country
HAVING COUNT(tc.c_customer_sk) > 0 OR SUM(is.average_income_estimate) > 100000
ORDER BY total_income_estimate DESC, customer_count ASC;
