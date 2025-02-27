
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(TRIM(ca_street_number), ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(TRIM(ca_street_number), ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        COALESCE(cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer_demographics
),
AggregatedData AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.cd_purchase_estimate,
        ad.full_address,
        ad.address_length
    FROM 
        AddressDetails ad
    JOIN 
        DemographicDetails dd ON ad.ca_state = dd.cd_marital_status -- Note: Assuming a fictional join condition for demonstration
)
SELECT 
    ca_city,
    ca_state,
    ca_zip,
    COUNT(*) AS total_customer_count,
    AVG(address_length) AS avg_address_length,
    STRING_AGG(DISTINCT credit_rating, ', ') AS unique_credit_ratings
FROM 
    AggregatedData
GROUP BY 
    ca_city, ca_state, ca_zip
ORDER BY 
    total_customer_count DESC
LIMIT 
    10;
