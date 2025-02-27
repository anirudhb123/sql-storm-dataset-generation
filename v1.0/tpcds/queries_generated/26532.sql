
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country
),
CustomerInfo AS (
    SELECT 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        address_info.full_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo AS address_info ON c.c_current_addr_sk = address_info.full_address
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    full_address,
    COUNT(full_address) OVER(PARTITION BY full_address) AS address_frequency,
    ROW_NUMBER() OVER(ORDER BY full_address) AS address_rank
FROM 
    CustomerInfo
WHERE 
    cd_gender = 'F'
ORDER BY 
    address_rank
LIMIT 100;
