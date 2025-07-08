
WITH CustomerAddressData AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
),
CustomerDemographicsData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cad.full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        CustomerAddressData cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        CustomerDemographicsData cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    c.c_email_address AS email_address,
    COUNT(*) AS unique_addresses,
    LISTAGG(c.full_address, '; ') AS all_addresses,
    c.cd_gender AS gender,
    c.cd_marital_status AS marital_status,
    SUM(c.cd_purchase_estimate) AS total_purchase_estimate
FROM 
    CombinedData c
GROUP BY 
    c.c_first_name, c.c_last_name, c.c_email_address, c.cd_gender, c.cd_marital_status
ORDER BY 
    total_purchase_estimate DESC
LIMIT 100;
