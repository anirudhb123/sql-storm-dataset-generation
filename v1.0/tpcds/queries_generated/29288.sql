
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT ca_zip) AS unique_zips,
        STRING_AGG(ca_street_name, ', ') AS street_names
    FROM customer_address
    GROUP BY ca_state
),
demographic_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_education_status, ', ') AS education_statuses
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
date_summary AS (
    SELECT 
        EXTRACT(YEAR FROM d_date) AS year,
        COUNT(DISTINCT d_date_sk) AS unique_days,
        STRING_AGG(d_day_name, ', ') AS week_days,
        AVG(d_dow) AS avg_day_of_week
    FROM date_dim
    GROUP BY year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.unique_cities,
    a.unique_zips,
    a.street_names,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.education_statuses,
    date.year,
    date.unique_days,
    date.week_days,
    date.avg_day_of_week
FROM address_summary a
JOIN demographic_summary d ON a.unique_addresses > 0
JOIN date_summary date ON date.unique_days > 0
ORDER BY a.ca_state, d.cd_gender, date.year;
