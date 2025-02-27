
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS all_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
demographic_summary AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_id) AS total_days,
        STRING_AGG(DISTINCT d_day_name, ', ') AS unique_days
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.total_addresses,
    a.all_streets,
    d.cd_gender,
    d.total_dependents,
    d.avg_purchase_estimate,
    date.d_year,
    date.total_days,
    date.unique_days
FROM 
    address_summary a
JOIN 
    demographic_summary d ON d.total_dependents > 0
JOIN 
    date_summary date ON date.total_days > 0
ORDER BY 
    a.ca_state, a.ca_city, d.cd_gender;
