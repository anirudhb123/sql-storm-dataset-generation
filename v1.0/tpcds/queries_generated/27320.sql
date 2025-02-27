
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedAddresses AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ad.ca_city, ad.ca_state ORDER BY ad.address_length DESC) AS address_rank
    FROM 
        AddressData ad
)
SELECT 
    c.full_name,
    ra.full_address,
    ra.address_length
FROM 
    CustomerData c
JOIN 
    RankedAddresses ra ON ra.address_rank = 1
WHERE 
    ra.ca_country = 'USA'
ORDER BY 
    c.full_name ASC, ra.address_length DESC;
