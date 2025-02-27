
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_date_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_amt DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        (CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low Spender'
            WHEN cd.cd_purchase_estimate < 500 THEN 'Medium Spender'
            ELSE 'High Spender'
        END) AS spending_category
    FROM customer_demographics cd
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS total_returning_customers,
    SUM(COALESCE(rr.sr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(rr.sr_return_amt, 0)) AS total_return_amt,
    MAX(rr.sr_return_amt) AS max_return_amt,
    AVG(rr.sr_return_amt) FILTER (WHERE rr.rn <= 3) AS avg_top_3_return_amt,
    STRING_AGG(cd.spending_category, ', ') AS spending_categories
FROM customer_address ca
LEFT JOIN RankedReturns rr ON ca.ca_address_sk = rr.sr_addr_sk
JOIN CustomerDemographics cd ON rr.sr_customer_sk = cd.cd_demo_sk
WHERE ca.ca_state IN ('CA', 'NY', 'TX')
  AND (EXISTS (
      SELECT 1
      FROM date_dim DD
      WHERE DD.d_date_sk = rr.sr_return_date_sk
        AND DD.d_year = 2023
        AND DD.d_weekend = 'Y')
  OR rr.sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns))
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_return_amount DESC,
         STRING_LENGTH(ca.ca_city) ASC
LIMIT 50;
