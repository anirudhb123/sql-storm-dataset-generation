
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(c_demo_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.address_list,
    c.cd_gender,
    c.customer_count,
    c.avg_dependents,
    c.marital_statuses
FROM 
    AddressSummary a
JOIN 
    CustomerDemographics c ON a.ca_state IS NOT NULL
ORDER BY 
    a.unique_addresses DESC, 
    c.customer_count DESC;
