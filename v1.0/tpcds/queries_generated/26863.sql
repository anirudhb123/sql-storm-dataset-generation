
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) as address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS full_street_address
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) as total_purchase_estimate,
        COUNT(*) as demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
MergedData AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.address_count,
        ad.full_street_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_purchase_estimate,
        cd.demographic_count
    FROM 
        AddressDetails ad
    JOIN 
        CustomerDemographics cd ON ad.address_count > 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.full_street_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_purchase_estimate,
    cd.demographic_count
FROM 
    MergedData ca
JOIN 
    customer c ON c.c_current_addr_sk = (
        SELECT 
            ca_address_sk 
        FROM 
            customer_address 
        WHERE 
            ca_city = ca.ca_city 
            AND ca_state = ca.ca_state
        LIMIT 1
    )
WHERE 
    c.c_birth_country = 'USA'
ORDER BY 
    ca.ca_city, ca.ca_state;
