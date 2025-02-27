
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        STRING_AGG(CONCAT(cd_gender, ' - ', cd_marital_status, ' (', cd_dep_count, ' dependents)'), '; ') AS demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
CombinedStats AS (
    SELECT 
        A.ca_city,
        A.ca_state,
        A.address_count,
        A.full_addresses,
        D.cd_gender,
        D.cd_marital_status,
        D.demographic_count,
        D.demographics
    FROM 
        AddressStats A
    JOIN 
        DemographicStats D ON A.ca_state = D.cd_gender  -- Artificial join for this query purpose
)
SELECT 
    ca_city,
    ca_state,
    address_count,
    full_addresses,
    cd_gender,
    cd_marital_status,
    demographic_count,
    demographics
FROM 
    CombinedStats
WHERE 
    address_count > 10 AND demographic_count > 5
ORDER BY 
    ca_city, ca_state, cd_gender, cd_marital_status;
