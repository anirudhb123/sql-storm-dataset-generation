
WITH Address_City AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate, 
        cd_credit_rating
    FROM 
        customer_demographics
),
Customer_Addresses AS (
    SELECT 
        c.c_customer_sk,
        a.ca_city,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        Address_City a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
Augmented_Addresses AS (
    SELECT 
        customer_sk,
        ca_city,
        full_address,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr.'
            ELSE 'Ms.'
        END AS salutation,
        LENGTH(full_address) AS address_length,
        UPPER(ca_city) AS city_uppercase
    FROM 
        Customer_Addresses
)
SELECT 
    customer_sk,
    salutation,
    ca_city,
    full_address,
    cd_marital_status,
    cd_purchase_estimate,
    address_length,
    city_uppercase
FROM 
    Augmented_Addresses
WHERE 
    cd_purchase_estimate > 50000
ORDER BY 
    address_length DESC, 
    ca_city ASC
LIMIT 100;
