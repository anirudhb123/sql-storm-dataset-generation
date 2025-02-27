
WITH AddressDetails AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type), '; ') AS full_addresses
    FROM 
        customer_address ca
    GROUP BY 
        ca.city, ca.state
),
Demographics AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd.education_status, ', ') AS education_level
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.gender, cd.marital_status
),
CombinedData AS (
    SELECT 
        ad.city,
        ad.state,
        ad.address_count,
        ad.full_addresses,
        d.gender,
        d.marital_status,
        d.avg_purchase_estimate,
        d.education_level
    FROM 
        AddressDetails ad
    JOIN 
        Demographics d ON ad.address_count > 100
)
SELECT 
    city,
    state,
    address_count,
    full_addresses,
    gender,
    marital_status,
    avg_purchase_estimate,
    education_level
FROM 
    CombinedData
WHERE 
    avg_purchase_estimate > 5000
ORDER BY 
    state, city, avg_purchase_estimate DESC;
