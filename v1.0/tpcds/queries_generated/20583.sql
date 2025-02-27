
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state, level + 1
    FROM customer_address
    JOIN AddressHierarchy ON AddressHierarchy.ca_address_sk = customer_address.ca_address_sk + 1
    WHERE AddressHierarchy.level < 5
),
RankedDemographics AS (
    SELECT cd_gender, COUNT(DISTINCT c_customer_id) AS customer_count,
           RANK() OVER (PARTITION BY cd_gender ORDER BY COUNT(DISTINCT c_customer_id) DESC) AS gender_rank
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender
),
FilteredSales AS (
    SELECT ws.s_ship_mode_sk, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit,
           IIF(ws.ws_net_paid < 0, 'Overdrawn', 'Healthy') AS financial_status
    FROM web_sales ws
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk > (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022 AND d_month_seq = 2
    )
    GROUP BY ws.ws_ship_mode_sk
)
SELECT ah.ca_city, ah.ca_state, rd.cd_gender, rd.customer_count, fs.financial_status,
       COALESCE(SUM(fs.total_quantity), 0) AS quantity_sold,
       COALESCE(SUM(fs.total_profit), 0) AS profit_generated,
       JSON_ARRAYAGG(DISTINCT ah.ca_address_id) AS address_ids
FROM AddressHierarchy ah
FULL OUTER JOIN RankedDemographics rd ON 1 = (CASE WHEN rd.gender_rank = 1 THEN 1 ELSE 0 END)
FULL OUTER JOIN FilteredSales fs ON fs.s_ship_mode_sk = rd.gender_rank
WHERE (rd.customer_count > 50 OR fs.total_profit > 1000)
  AND (ah.ca_state = 'CA' OR ah.ca_city IS NULL)
GROUP BY ah.ca_city, ah.ca_state, rd.cd_gender, rd.customer_count, fs.financial_status
ORDER BY ah.ca_state, rd.customer_count DESC, fs.financial_status;
