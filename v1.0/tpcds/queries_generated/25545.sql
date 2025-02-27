
WITH AddressPatterns AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicPatterns AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
BenchmarkingData AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        LENGTH(a.full_address) AS address_length,
        LENGTH(d.cd_education_status) AS education_length,
        SUBSTRING(a.ca_city, 1, 5) AS city_prefix,
        SUBSTRING(d.cd_marital_status, 1, 1) AS marital_short
    FROM 
        AddressPatterns a
    JOIN 
        DemographicPatterns d ON LENGTH(a.full_address) > 0 AND d.cd_purchase_estimate > 100
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    address_length,
    education_length,
    city_prefix,
    marital_short,
    CONCAT('Check Address: ', full_address, ' in ', ca_city, ', ', ca_state, ', Zip: ', ca_zip) AS address_check,
    COUNT(*) OVER (PARTITION BY ca_state) AS address_count_per_state
FROM 
    BenchmarkingData
ORDER BY 
    ca_state, address_length DESC
LIMIT 100;
