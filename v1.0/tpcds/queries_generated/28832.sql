
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressStats AS (
    SELECT
        ad.ca_state,
        COUNT(ad.ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ad.full_address, '; ') AS unique_addresses
    FROM 
        AddressDetails ad
    GROUP BY 
        ad.ca_state
),
GenderStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.c_customer_sk) AS gender_count
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.cd_gender
),
MaritalStatusStats AS (
    SELECT 
        cd.cd_marital_status,
        COUNT(cd.c_customer_sk) AS marital_status_count
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.cd_marital_status
)
SELECT 
    a.ca_state,
    a.address_count,
    a.unique_addresses,
    g.cd_gender,
    g.gender_count,
    m.cd_marital_status,
    m.marital_status_count
FROM 
    AddressStats a
LEFT JOIN 
    GenderStats g ON a.address_count > 0
LEFT JOIN 
    MaritalStatusStats m ON a.address_count > 0
ORDER BY 
    a.ca_state, g.cd_gender, m.cd_marital_status;
