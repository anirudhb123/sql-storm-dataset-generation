
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        LISTAGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), 
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.total_addresses,
    a.avg_gmt_offset,
    a.street_names,
    d.cd_gender,
    d.total_demographics,
    d.avg_purchase_estimate,
    d.education_statuses
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.total_addresses > 100 AND d.total_demographics > 50
ORDER BY 
    a.ca_city, a.ca_state, d.cd_gender;
