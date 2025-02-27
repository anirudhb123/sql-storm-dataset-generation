
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 2000
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CA_CITY,
        CA_STATE,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS complete_address,
        ROW_NUMBER() OVER (PARTITION BY CA_CITY ORDER BY ca.ca_address_sk DESC) AS rna
    FROM customer_address ca
    WHERE ca.ca_state IN ('CA', 'NY')
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ad.complete_address,
    ad.CA_CITY,
    ad.CA_STATE
FROM RankedCustomers rc
JOIN AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
WHERE rc.rn <= 10 AND ad.rna <= 5
ORDER BY ad.CA_CITY, rc.full_name;
