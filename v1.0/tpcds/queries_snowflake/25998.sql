
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        UPPER(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographics,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
CustomerAddressDemographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.demographics
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    cad.full_name,
    cad.full_address,
    cad.ca_city,
    cad.ca_state,
    cad.ca_zip,
    cad.ca_country,
    cad.demographics,
    COUNT(*) AS address_count,
    LISTAGG(cad.demographics, '; ') WITHIN GROUP (ORDER BY cad.demographics) AS all_demographics
FROM 
    CustomerAddressDemographics cad
WHERE 
    cad.ca_state = 'CA'
GROUP BY 
    cad.full_name, cad.full_address, cad.ca_city, cad.ca_state, cad.ca_zip, cad.ca_country, cad.demographics
ORDER BY 
    address_count DESC, cad.full_name
LIMIT 100;
