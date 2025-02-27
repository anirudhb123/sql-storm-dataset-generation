
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ad.full_address,
        ad.city_state_zip,
        ad.street_name_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_id
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    street_name_length,
    COUNT(*) OVER (PARTITION BY cd_gender) AS count_by_gender,
    COUNT(*) OVER (PARTITION BY cd_marital_status) AS count_by_marital_status
FROM 
    CustomerDetails
WHERE 
    street_name_length > 5
ORDER BY 
    full_name;
