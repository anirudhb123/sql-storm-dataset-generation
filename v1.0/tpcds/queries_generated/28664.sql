
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
), 
CustomerAddressRank AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        ROW_NUMBER() OVER (PARTITION BY rc.cd_gender ORDER BY rc.cd_purchase_estimate DESC) AS address_rnk
    FROM 
        RankedCustomers rc
    JOIN 
        AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country
FROM 
    CustomerAddressRank
WHERE 
    rnk <= 10 AND address_rnk <= 5
ORDER BY 
    cd_gender, cd_purchase_estimate DESC;
