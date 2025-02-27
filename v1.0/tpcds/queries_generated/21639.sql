
WITH RECURSIVE AddressCount AS (
    SELECT ca_address_sk, ca_city, ca_state, COUNT(c_customer_sk) AS customer_count
    FROM customer_address
    LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state
),
SalesAnalysis AS (
    SELECT ws_bill_cdemo_sk, SUM(ws_net_paid) AS total_spent,
           DENSE_RANK() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_paid) DESC) AS spending_rank
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
CustomerDemographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate,
           LEAD(cd_purchase_estimate) OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate) AS next_estimate,
           NULLIF(cd_purchase_estimate - LAG(cd_purchase_estimate) OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate), 0) AS estimate_diff
    FROM customer_demographics
)
SELECT DISTINCT ca.ca_address_id, 
                ca.ca_city, 
                ca.ca_state, 
                COALESCE(ac.customer_count, 0) AS customer_count,
                cd.cd_gender,
                cd.marital_status,
                CASE 
                    WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
                    WHEN cd.cd_purchase_estimate <= 1000 THEN 'Low spender'
                    WHEN cd.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium spender'
                    ELSE 'High spender'
                END AS spending_category,
                sa.total_spent
FROM customer_address ca
LEFT JOIN AddressCount ac ON ca.ca_address_sk = ac.ca_address_sk
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk = ac.customer_count
LEFT JOIN SalesAnalysis sa ON sa.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state IN ('CA', 'NY')
  AND EXISTS (SELECT 1 FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk AND c.c_first_name IS NOT NULL)
  AND (cd.cd_gender IS NULL OR cd.cd_gender = 'F')
  AND (SELECT COUNT(*) FROM date_dim d WHERE d.d_year < 2020) > 0
UNION ALL
SELECT ca.ca_address_id, 
     ca.ca_city, 
     ca.ca_state, 
     COALESCE(ac.customer_count, 0) AS customer_count,
     cd.cd_gender,
     cd.marital_status,
     'Business' AS spending_category,
     SUM(ws_net_paid) AS total_spent
FROM custom_address ca
LEFT JOIN AddressCount ac ON ca.ca_address_sk = ac.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk = ac.customer_count
GROUP BY ca.ca_address_sk, ac.customer_count, cd.cd_gender, cd.marital_status
HAVING SUM(ws_net_paid) > 1000
ORDER BY total_spent DESC
LIMIT 100;
