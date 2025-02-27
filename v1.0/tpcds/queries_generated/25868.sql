
WITH AddressData AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        LENGTH(ca.ca_street_name) AS street_length,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        REGEXP_REPLACE(ca.ca_zip, '([0-9]{5})(-[0-9]{4})?', '\\1') AS cleaned_zip
    FROM 
        customer_address ca
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        c.c_email_address,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    COUNT(DISTINCT cd.full_name) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(ad.street_length) AS min_street_length,
    MAX(ad.street_length) AS max_street_length,
    STRING_AGG(DISTINCT ad.full_address, '; ') AS unique_addresses
FROM 
    AddressData ad
JOIN 
    CustomerData cd ON 1 = 1
GROUP BY 
    ad.ca_city, 
    ad.ca_state
ORDER BY 
    ad.ca_city, 
    ad.ca_state;
