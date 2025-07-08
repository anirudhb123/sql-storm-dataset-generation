
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDemographicDetails AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        UPPER(cd.cd_education_status) AS education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
CustomerFullDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        CustomerAddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerDemographicDetails cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cfd.full_name,
    cfd.full_address,
    cfd.ca_city,
    cfd.ca_state,
    cfd.ca_zip,
    cfd.cd_gender,
    cfd.cd_marital_status,
    cfd.education_status,
    LISTAGG(DISTINCT CONCAT(cfd.cd_gender, '-', cfd.cd_marital_status), ', ') AS demographic_summary
FROM 
    CustomerFullDetails cfd
GROUP BY 
    cfd.full_name,
    cfd.full_address,
    cfd.ca_city,
    cfd.ca_state,
    cfd.ca_zip,
    cfd.cd_gender,
    cfd.cd_marital_status,
    cfd.education_status
ORDER BY 
    cfd.ca_state, cfd.ca_city, cfd.full_name
LIMIT 100;
