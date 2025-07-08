
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        ARRAY_AGG(ca_city) AS cities,
        MAX(ca_gmt_offset) AS max_gmt_offset,
        MIN(ca_gmt_offset) AS min_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        ARRAY_AGG(cd_marital_status) AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CombinedResults AS (
    SELECT 
        ac.ca_state,
        ac.address_count,
        ac.cities,
        ds.cd_gender,
        ds.demo_count,
        ds.avg_purchase_estimate,
        ds.marital_statuses
    FROM 
        AddressCounts ac
    JOIN 
        DemographicsSummary ds ON ac.address_count > 100
)
SELECT 
    ca.ca_state,
    ca.address_count,
    ca.cities,
    dm.cd_gender,
    dm.demo_count,
    dm.avg_purchase_estimate,
    dm.marital_statuses,
    LENGTH(ca.cities) AS total_city_length,
    ARRAY_AGG(DISTINCT dm.marital_statuses) AS unique_marital_statuses
FROM 
    CombinedResults ca
JOIN 
    DemographicsSummary dm ON ca.cd_gender = dm.cd_gender
GROUP BY 
    ca.ca_state, 
    ca.address_count, 
    ca.cities, 
    dm.cd_gender, 
    dm.demo_count, 
    dm.avg_purchase_estimate, 
    dm.marital_statuses
ORDER BY 
    ca.address_count DESC, 
    dm.demo_count ASC;
