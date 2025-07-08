
WITH CustomerAddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS cities,
        SUM(CASE WHEN ca_suite_number IS NOT NULL THEN 1 ELSE 0 END) AS suite_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),

DemographicsSummary AS (
    SELECT 
        cd_marital_status,
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_marital_status, cd_gender
)

SELECT 
    cas.ca_state,
    cas.unique_addresses,
    cas.cities,
    cas.suite_count,
    ds.cd_marital_status,
    ds.cd_gender,
    ds.total_customers,
    ds.avg_purchase_estimate,
    ds.education_levels
FROM 
    CustomerAddressSummary cas
JOIN 
    DemographicsSummary ds ON ds.total_customers > 0
ORDER BY 
    cas.ca_state, ds.cd_marital_status, ds.cd_gender;
