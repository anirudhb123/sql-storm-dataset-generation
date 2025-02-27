
WITH address_summary AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM customer_address
    GROUP BY ca_city, ca_state
),
demographics_summary AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
time_analysis AS (
    SELECT
        d_year,
        d_month_seq,
        COUNT(DISTINCT d_date_sk) AS total_days,
        STRING_AGG(DISTINCT d_day_name, ', ') AS days_names
    FROM date_dim
    GROUP BY d_year, d_month_seq
)
SELECT
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.street_names,
    a.street_types,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.education_levels,
    t.d_year,
    t.d_month_seq,
    t.total_days,
    t.days_names
FROM address_summary a
JOIN demographics_summary d ON a.ca_state = 'CA' AND d.cd_gender = 'F'
JOIN time_analysis t ON t.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY a.address_count DESC, d.demographic_count DESC;
