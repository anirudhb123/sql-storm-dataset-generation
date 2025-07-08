
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, COALESCE(CONCAT(' Apt ', ca_suite_number), '')) AS full_address,
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
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    LISTAGG(cd.cd_education_status, ', ') WITHIN GROUP (ORDER BY cd.cd_education_status) AS education_levels,
    LISTAGG(DISTINCT CONCAT(cd.ca_city, ', ', cd.ca_state), '; ') WITHIN GROUP (ORDER BY cd.ca_city, cd.ca_state) AS unique_cities_states,
    LISTAGG(cd.full_address, '; ') WITHIN GROUP (ORDER BY cd.full_address) AS full_addresses
FROM 
    CustomerDetails cd
WHERE 
    cd.cd_purchase_estimate > 5000
GROUP BY 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY 
    customer_count DESC;
