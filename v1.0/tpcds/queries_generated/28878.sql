
WITH AddressInfo AS (
    SELECT 
        ca_state,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name)) AS address_length
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_level
    FROM 
        customer_demographics
),
CompositeInfo AS (
    SELECT 
        a.ca_state,
        a.ca_city,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.purchase_level
    FROM 
        AddressInfo a
    JOIN 
        DemographicInfo d ON a.ca_state = 'NY' AND d.cd_gender = 'F'
),
StringBenchmark AS (
    SELECT 
        ca_state,
        ca_city,
        full_address,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        purchase_level,
        UPPER(full_address) AS upper_address,
        LOWER(full_address) AS lower_address,
        TRIM(full_address) AS trimmed_address,
        REPLACE(full_address, ' ', '-') AS address_with_dashes
    FROM 
        CompositeInfo
)
SELECT 
    ca_state,
    ca_city,
    full_address,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    purchase_level,
    upper_address,
    lower_address,
    trimmed_address,
    address_with_dashes
FROM 
    StringBenchmark
WHERE 
    address_length > 30
ORDER BY 
    ca_state, ca_city;
