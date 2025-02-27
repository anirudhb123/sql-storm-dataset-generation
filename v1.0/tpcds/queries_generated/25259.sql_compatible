
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_country IN ('USA', 'Canada')
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
FullAddressInfo AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.cd_education_status,
        dm.cd_purchase_estimate,
        dm.cd_credit_rating
    FROM 
        AddressDetails ad
    JOIN 
        DemographicDetails dm ON 1=1  
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COUNT(*) AS address_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(cd_gender, ', ') AS unique_genders,
    STRING_AGG(cd_marital_status, ', ') AS unique_marital_statuses
FROM 
    FullAddressInfo
GROUP BY 
    full_address, ca_city, ca_state, ca_zip, ca_country
ORDER BY 
    address_count DESC, ca_country ASC;
