
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS total_demographics,
        AVG(cd_dep_count) AS avg_dependent_count,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS total_days,
        STRING_AGG(DISTINCT d_day_name, ', ') AS week_days,
        AVG(d_month_seq) AS avg_month_sequence
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.unique_cities,
    a.avg_gmt_offset,
    a.address_list,
    d.cd_gender,
    d.total_demographics,
    d.avg_dependent_count,
    d.marital_statuses,
    d.education_levels,
    date.d_year,
    date.total_days,
    date.week_days,
    date.avg_month_sequence
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.co_state = 'CA'  -- Example filter for California addresses
JOIN 
    date_summary date ON date.d_year = 2023         -- Filter for year 2023
ORDER BY 
    a.ca_state, d.cd_gender, date.d_year;
