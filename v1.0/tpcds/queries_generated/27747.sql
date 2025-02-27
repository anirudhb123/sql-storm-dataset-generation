
WITH StringMetrics AS (
    SELECT 
        ca_address_id,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_zip) AS zip_length,
        LENGTH(ca_country) AS country_length,
        CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LOWER(ca_street_name) AS street_name_lower,
        UPPER(ca_city) AS city_upper,
        REPLACE(ca_country, ' ', '-') AS country_dash
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
AggregatedData AS (
    SELECT 
        sm.sm_type AS ship_mode,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
)
SELECT 
    sm.ship_mode,
    dm.cd_gender,
    dm.cd_marital_status,
    COUNT(sm.total_orders) AS order_count,
    SUM(sm.total_profit) AS total_revenue,
    AVG(s.street_name_length) AS avg_street_name_length,
    AVG(s.city_length) AS avg_city_length,
    AVG(s.state_length) AS avg_state_length,
    GROUP_CONCAT(DISTINCT s.full_address) AS addresses_list
FROM StringMetrics s
JOIN Demographics dm ON LENGTH(s.street_name_lower) = LENGTH(dm.cd_marital_status)  -- arbitrary join condition for complexity
JOIN AggregatedData sm ON sm.ship_mode = s.city_upper  -- arbitrary join condition
GROUP BY sm.ship_mode, dm.cd_gender, dm.cd_marital_status
ORDER BY total_revenue DESC;
