
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_country) AS country_upper,
        LENGTH(ca_zip) AS zip_length
    FROM customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_count AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM processed_addresses
    GROUP BY ca_city
),
final_result AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        pa.full_address,
        pa.zip_length,
        ac.address_count,
        pa.country_upper
    FROM customer_info ci
    JOIN processed_addresses pa ON ci.c_customer_sk = pa.ca_address_sk
    JOIN address_count ac ON pa.city_lower = LOWER(ac.ca_city)
    WHERE pa.zip_length > 5 AND ac.address_count > 10
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    full_address, 
    zip_length, 
    address_count, 
    country_upper
FROM final_result
ORDER BY address_count DESC, full_name;
