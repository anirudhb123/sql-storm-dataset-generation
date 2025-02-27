
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, IFNULL(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_upper,
        TRIM(ca_zip) AS trimmed_zip
    FROM customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    a.full_address,
    a.city_upper,
    a.trimmed_zip,
    d.full_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    a.street_name_length
FROM processed_addresses a
JOIN customer_details d ON a.ca_address_sk = d.c_customer_sk
WHERE a.city_upper LIKE 'N%' 
AND d.cd_purchase_estimate > 500
ORDER BY a.street_name_length DESC, d.full_name;
