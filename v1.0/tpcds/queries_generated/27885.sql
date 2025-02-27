
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.city,
        ad.state,
        ad.zip,
        ad.country,
        ROW_NUMBER() OVER (PARTITION BY c.c_gender ORDER BY ad.address_length DESC) AS row_num
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails AS ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.full_address,
    cd.city,
    cd.state,
    cd.zip,
    cd.country
FROM CustomerDetails AS cd
WHERE cd.row_num <= 5 AND cd.cd_gender = 'M'
ORDER BY cd.address_length DESC;
