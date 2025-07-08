
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, COALESCE(CONCAT(' ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_demo_sk
    FROM 
        customer_demographics
),
AggregatedData AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        AddressDetails ad
    JOIN 
        customer c ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        ad.full_address, ad.ca_city, ad.ca_state, ad.ca_zip, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    customer_count,
    avg_purchase_estimate,
    LISTAGG(CONCAT('Gender: ', cd_gender, ', Marital Status: ', cd_marital_status), '; ') AS demographic_summary
FROM 
    AggregatedData
WHERE 
    avg_purchase_estimate > 1000
GROUP BY 
    full_address, ca_city, ca_state, ca_zip, cd_gender, cd_marital_status, cd_education_status, customer_count, avg_purchase_estimate
ORDER BY 
    customer_count DESC
LIMIT 20;
