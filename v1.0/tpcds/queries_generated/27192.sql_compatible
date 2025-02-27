
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_city || ': ' || COUNT(*), ', ' ORDER BY COUNT(*) DESC) AS city_distribution,
        SUM(CASE WHEN ca_street_type = 'Street' THEN 1 ELSE 0 END) AS street_count,
        SUM(CASE WHEN ca_street_type = 'Avenue' THEN 1 ELSE 0 END) AS avenue_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        STRING_AGG(cd_marital_status || ' (' || COUNT(*) || ')', ', ' ORDER BY COUNT(*) DESC) AS marital_distribution,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(*) AS total_days,
        STRING_AGG(d_day_name, ', ') AS day_names
    FROM 
        date_dim 
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.city_distribution,
    a.street_count,
    a.avenue_count,
    d.cd_gender,
    d.total_demographics,
    d.marital_distribution,
    d.avg_dependents,
    d.avg_purchase_estimate,
    dt.d_year,
    dt.total_days,
    dt.day_names
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = (SELECT MIN(ca_address_sk) FROM customer_address))
CROSS JOIN 
    date_summary dt
WHERE 
    a.total_addresses > 0
ORDER BY 
    a.total_addresses DESC, d.total_demographics DESC, dt.d_year DESC;
