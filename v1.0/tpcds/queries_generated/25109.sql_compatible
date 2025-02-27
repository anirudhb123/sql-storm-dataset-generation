
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographics_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.address_count,
    a.unique_cities,
    a.avg_street_name_length,
    a.street_types,
    d.cd_gender,
    d.demographics_count,
    d.avg_purchase_estimate,
    d.marital_statuses
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.address_count > d.demographics_count
ORDER BY 
    a.address_count DESC, d.demographics_count ASC
LIMIT 50;
