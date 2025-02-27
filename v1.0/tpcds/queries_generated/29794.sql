
WITH AddressAggregates AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
CombinedData AS (
    SELECT 
        aa.ca_state,
        aa.address_count,
        aa.cities,
        aa.street_names,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_purchase_estimate,
        cd.avg_dep_count
    FROM 
        AddressAggregates aa
    JOIN 
        CustomerDemographics cd ON (AA.address_count > 100) AND (cd.total_purchase_estimate > 5000)
)
SELECT 
    ca_state,
    address_count,
    cities,
    street_names,
    cd_gender,
    cd_marital_status,
    total_purchase_estimate,
    avg_dep_count
FROM 
    CombinedData
ORDER BY 
    address_count DESC, total_purchase_estimate DESC;
