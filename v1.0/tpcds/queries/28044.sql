
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(ca_address_id) AS total_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
TopDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(cd_demo_sk) AS demographic_count,
        STRING_AGG(cd_education_status, ', ') AS education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
    ORDER BY 
        demographic_count DESC
    LIMIT 5
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.address_list,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.education_statuses
FROM 
    AddressSummary a
JOIN 
    TopDemographics d ON a.total_addresses > 50
ORDER BY 
    a.total_addresses DESC, d.demographic_count DESC;
