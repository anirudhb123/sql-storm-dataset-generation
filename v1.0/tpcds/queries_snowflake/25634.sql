
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        LOWER(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(LOWER(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)))) AS address_length
    FROM 
        customer_address
),
ProcessedDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital,
        REPLACE(CAST(cd_purchase_estimate AS VARCHAR), ' ', '') AS purchase_estimate
    FROM 
        customer_demographics
),
CombinedData AS (
    SELECT 
        PA.ca_address_sk,
        PA.full_address,
        PD.cd_demo_sk,
        PD.gender_marital,
        PD.purchase_estimate,
        PA.ca_city,
        PA.ca_state,
        PA.ca_zip,
        PA.address_length
    FROM 
        ProcessedAddresses PA
    JOIN 
        ProcessedDemographics PD ON PD.cd_demo_sk = PA.ca_address_sk % 100000 
)
SELECT 
    ca_city,
    ca_state,
    COUNT(*) AS total_addresses,
    AVG(address_length) AS avg_address_length,
    LISTAGG(gender_marital, ', ') AS demographics_info
FROM 
    CombinedData
GROUP BY 
    ca_city,
    ca_state
ORDER BY 
    total_addresses DESC
LIMIT 10;
