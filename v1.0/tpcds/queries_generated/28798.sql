
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
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(COALESCE(c_salutation, ''), ' ', c_first_name, ' ', c_last_name) AS full_customer_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CombinedDetails AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_customer_name,
        cd.c_email_address,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ed_education_status
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
)
SELECT 
    full_customer_name,
    c_email_address,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    cd_marital_status,
    cd_education_status
FROM 
    CombinedDetails
WHERE 
    ca_state = 'CA' 
    AND cd_purchase_estimate > 500
ORDER BY 
    ca_city, full_customer_name;
