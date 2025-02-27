
WITH AddressAnalysis AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY', 'TX')
),
DemographicsAnalysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ARRAY_AGG(DISTINCT cd_purchase_estimate) AS purchase_estimates,
        COUNT(cd_demo_sk) AS demographics_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
FullAnalysis AS (
    SELECT 
        a.ca_address_id,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.purchase_estimates,
        a.address_length
    FROM 
        AddressAnalysis a
    JOIN 
        DemographicsAnalysis d ON d.demographics_count > 0
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    address_length,
    STRING_AGG(DISTINCT CAST(purchase_estimates AS VARCHAR), ', ') AS unique_purchase_estimates
FROM 
    FullAnalysis
GROUP BY 
    full_address, ca_city, ca_state, ca_zip, cd_gender, cd_marital_status, address_length
ORDER BY 
    address_length DESC;
