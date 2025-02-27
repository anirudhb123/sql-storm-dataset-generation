
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, NULL::integer AS parent_address_sk
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, ah.ca_address_sk
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_street_number = '12' AND a.ca_city = ah.ca_city
    WHERE ah.ca_state IS NOT NULL
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cd.cd_credit_rating,
           DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer_demographics cd
    WHERE cd.cd_credit_rating IS NOT NULL
),
SalesSummary AS (
    SELECT s.ss_sold_date_sk, SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    GROUP BY s.ss_sold_date_sk
),
IncomeBands AS (
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, 
           CASE WHEN ib.ib_lower_bound IS NULL THEN 0 ELSE ib.ib_lower_bound END AS lower_bound_adj
    FROM income_band ib
)
SELECT
    ca.ca_address_id,
    cd.cd_gender,
    cb.total_net_profit,
    ib.ib_upper_bound,
    COALESCE(cb.total_quantity, 0) AS total_quantity,
    CASE 
        WHEN cb.total_net_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cb.total_net_profit DESC) AS gender_based_rank
FROM customer_address ca
LEFT JOIN CustomerDemographics cd ON ca.ca_address_sk = cd.cd_demo_sk
LEFT JOIN SalesSummary cb ON cb.ss_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)
LEFT JOIN IncomeBands ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE ca.ca_country IS NOT NULL OR ca.ca_state IS NULL
ORDER BY cb.total_net_profit DESC, cd.cd_gender ASC
FETCH FIRST 100 ROWS ONLY;
