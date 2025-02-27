
WITH AddressConcat AS (
    SELECT 
        ca.address_sk AS address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END, 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressConcat ad ON c.c_current_addr_sk = ad.address_sk
)
SELECT 
    gender_count.gender, 
    COUNT(*) AS customer_count, 
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT cd.full_address ORDER BY cd.full_address) AS unique_addresses
FROM 
    CustomerDetails cd
JOIN 
    (SELECT cd_gender AS gender, COUNT(*) AS count FROM customer_demographics GROUP BY cd_gender) gender_count ON cd.cd_gender = gender_count.gender
GROUP BY 
    gender_count.gender
ORDER BY 
    customer_count DESC;
