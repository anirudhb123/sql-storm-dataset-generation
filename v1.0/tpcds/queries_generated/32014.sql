
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopItems AS (
    SELECT ws_item_sk, SUM(ws_net_profit) AS total_profit
    FROM SalesCTE
    WHERE rn <= 10
    GROUP BY ws_item_sk
),
AddressInfo AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_country IS NOT NULL
),
CustomerDemographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_income_band_sk
    FROM customer_demographics
    WHERE cd_credit_rating = 'Good'
),
IncomeBound AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_upper_bound > 50000
)
SELECT 
    c.c_customer_id,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cd.cd_dep_count) AS average_dependents,
    MIN(ab.ib_lower_bound) AS min_income_band, 
    MAX(ab.ib_upper_bound) AS max_income_band,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN IncomeBound ab ON cd.cd_income_band_sk = ab.ib_income_band_sk
JOIN AddressInfo ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY c.c_customer_id, ca.ca_city, ca.ca_state, ca.ca_country
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 50;
