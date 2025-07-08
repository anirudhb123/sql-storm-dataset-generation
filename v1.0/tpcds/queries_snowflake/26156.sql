
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
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
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CombinedDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        dem.gender,
        dem.cd_marital_status,
        dem.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        CustomerDemographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
)
SELECT 
    gender,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    LISTAGG(CONCAT(c_first_name, ' ', c_last_name), ', ' ORDER BY c_last_name) AS customer_names
FROM 
    CombinedDetails
GROUP BY 
    gender
ORDER BY 
    customer_count DESC;
