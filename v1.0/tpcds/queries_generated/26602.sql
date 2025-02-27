
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
), DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), CombinedSummary AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.cities,
        a.unique_streets,
        a.street_types,
        d.cd_gender,
        d.demographic_count,
        d.avg_purchase_estimate,
        d.education_levels
    FROM 
        AddressSummary a
    FULL OUTER JOIN 
        DemographicsSummary d ON d.demographic_count > 0
)
SELECT 
    ca_state,
    address_count,
    cities,
    unique_streets,
    street_types,
    cd_gender,
    demographic_count,
    avg_purchase_estimate,
    education_levels
FROM 
    CombinedSummary
WHERE 
    address_count > 10 AND demographic_count > 5
ORDER BY 
    ca_state, cd_gender;
