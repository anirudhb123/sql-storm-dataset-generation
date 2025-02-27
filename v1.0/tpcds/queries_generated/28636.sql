
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(ca_street_name, '; ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.cities,
    ac.street_names,
    ds.cd_gender,
    ds.demo_count,
    ds.avg_purchase_estimate,
    ds.marital_statuses
FROM 
    AddressCounts ac
JOIN 
    DemographicStats ds ON ds.demo_count > 100
ORDER BY 
    ac.address_count DESC, ds.avg_purchase_estimate DESC
LIMIT 10;
