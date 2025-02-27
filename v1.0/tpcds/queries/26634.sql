
WITH AddressAnalysis AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)

SELECT 
    aa.ca_state,
    aa.address_count,
    aa.cities,
    cd.cd_gender,
    cd.customer_count,
    cd.avg_purchase_estimate,
    cd.marital_statuses,
    aa.full_addresses
FROM 
    AddressAnalysis aa
JOIN 
    CustomerDemographics cd 
ON 
    cd.customer_count > 100 
ORDER BY 
    aa.address_count DESC, 
    cd.customer_count DESC;
