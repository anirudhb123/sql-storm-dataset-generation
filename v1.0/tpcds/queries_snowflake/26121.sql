
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT CONCAT(ca_street_name, ' ', ca_street_type, ' ', ca_street_number), ', ') AS unique_addresses
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
    GROUP BY 
        ca_city
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(CONCAT(cd_marital_status, ' ', cd_education_status), ', ') AS marital_education_combination
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.unique_addresses,
    ds.cd_gender,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ds.marital_education_combination
FROM 
    AddressCounts ac
JOIN 
    DemographicSummary ds ON ds.customer_count > 100
ORDER BY 
    ac.address_count DESC, ds.avg_purchase_estimate DESC
LIMIT 50;
