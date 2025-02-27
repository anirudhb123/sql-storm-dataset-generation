
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS address_count,
        MAX(ca_city) AS sample_city,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, '; ') AS full_address_sample
    FROM 
        customer_address
    GROUP BY 
        ca_state
), DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographics_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), CombinedStats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.sample_city,
        a.full_address_sample,
        d.cd_gender,
        d.demographics_count,
        d.avg_purchase_estimate,
        d.marital_statuses
    FROM 
        AddressCounts a
    FULL OUTER JOIN 
        DemographicStats d ON a.ca_state IS NOT NULL OR d.cd_gender IS NOT NULL
)
SELECT 
    COALESCE(c.ca_state, d.cd_gender) AS category,
    SUM(COALESCE(c.address_count, 0)) AS total_addresses,
    SUM(COALESCE(d.demographics_count, 0)) AS total_demographics,
    AVG(COALESCE(d.avg_purchase_estimate, 0)) AS average_purchase_estimation,
    STRING_AGG(DISTINCT COALESCE(c.full_address_sample, ''), '; ') AS combined_address_samples,
    STRING_AGG(DISTINCT COALESCE(d.marital_statuses, ''), '; ') AS combined_marital_statuses
FROM 
    AddressCounts c
FULL OUTER JOIN 
    DemographicStats d ON c.ca_state IS NOT NULL OR d.cd_gender IS NOT NULL
GROUP BY 
    HAVING COUNT(DISTINCT COALESCE(c.ca_state, d.cd_gender)) > 1
ORDER BY 
    total_addresses DESC, total_demographics DESC;
