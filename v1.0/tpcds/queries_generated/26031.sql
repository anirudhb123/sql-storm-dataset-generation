
WITH AddressDetails AS (
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_fullname,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CombinedInfo AS (
    SELECT 
        ci.customer_fullname,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM 
        CustomerInfo ci
    JOIN 
        AddressDetails ad ON ci.c_customer_sk = ci.c_customer_sk
)
SELECT 
    ci.customer_fullname,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ad.full_address,
    COUNT(*) AS address_count_per_customer
FROM 
    CombinedInfo ci
JOIN 
    CombinedInfo ad ON ci.customer_fullname = ad.customer_fullname
GROUP BY 
    ci.customer_fullname, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status, ad.full_address
ORDER BY 
    address_count_per_customer DESC;
