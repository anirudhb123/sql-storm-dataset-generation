
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddressJoin AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(*) AS total_customers,
    STRING_AGG(ca.full_name, ', ') AS customer_names,
    STRING_AGG(CASE WHEN ca.cd_gender = 'M' THEN ca.full_name END, ', ') AS male_customers,
    STRING_AGG(CASE WHEN ca.cd_gender = 'F' THEN ca.full_name END, ', ') AS female_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    CustomerAddressJoin ca
JOIN 
    customer_demographics cd ON ca.cd_gender = cd.cd_gender
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_customers DESC;
