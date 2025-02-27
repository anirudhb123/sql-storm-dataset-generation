
WITH AddressAggregation AS (
    SELECT 
        ca_state,
        STRING_AGG(ca_city, ', ') AS city_list,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM customer_address
    GROUP BY ca_state
),
DemographicsAggregation AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        STRING_AGG(cd_education_status, ', ') AS education_list,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
DateAggregation AS (
    SELECT 
        d_year,
        STRING_AGG(d_day_name, ', ') AS day_names,
        COUNT(DISTINCT d_date_sk) AS unique_dates
    FROM date_dim
    GROUP BY d_year
),
SalesAggregation AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        STRING_AGG(DISTINCT sm.sm_ship_mode_id, ', ') AS shipping_modes
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.web_site_id
)
SELECT 
    a.ca_state AS state,
    a.city_list AS cities,
    a.address_count AS total_addresses,
    d.cd_gender AS gender,
    d.cd_marital_status AS marital_status,
    d.education_list AS education_statuses,
    d.total_purchase_estimate AS total_purchase,
    dt.d_year AS year,
    dt.day_names AS days_in_year,
    dt.unique_dates AS number_of_unique_dates,
    s.web_site_id AS website_id,
    s.total_net_profit AS net_profit,
    s.shipping_modes AS available_shipping_modes
FROM AddressAggregation a
JOIN DemographicsAggregation d ON a.address_count > 0
JOIN DateAggregation dt ON dt.unique_dates > 0
JOIN SalesAggregation s ON s.total_net_profit > 0
WHERE d.cd_purchase_estimate > 50000
ORDER BY a.ca_state, d.cd_gender, dt.d_year, s.total_net_profit DESC;
