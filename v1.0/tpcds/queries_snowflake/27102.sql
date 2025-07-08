
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS cities,
        LISTAGG(DISTINCT ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_type) AS street_types,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    GROUP BY ca_state
),
DemographicStatistics AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS demographic_count,
        LISTAGG(DISTINCT cd_gender, ', ') WITHIN GROUP (ORDER BY cd_gender) AS genders,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_marital_status
)
SELECT 
    a.ca_state,
    a.address_count,
    a.cities,
    a.street_types,
    a.avg_gmt_offset,
    d.cd_marital_status,
    d.demographic_count,
    d.genders,
    d.avg_purchase_estimate
FROM AddressStatistics a
JOIN DemographicStatistics d ON a.address_count = d.demographic_count
ORDER BY a.ca_state, d.cd_marital_status;
