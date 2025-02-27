
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        REGEXP_REPLACE(ca_city, '[^a-zA-Z ]', '') AS sanitized_city,
        UPPER(ca_state) AS upper_state
    FROM 
        customer_address
),
address_metrics AS (
    SELECT 
        sanitized_city,
        COUNT(*) AS city_count,
        AVG(address_length) AS avg_address_length,
        MAX(address_length) AS max_address_length,
        MIN(address_length) AS min_address_length
    FROM 
        processed_addresses
    GROUP BY 
        sanitized_city
)
SELECT 
    a.sanitized_city,
    a.city_count,
    a.avg_address_length,
    a.max_address_length,
    a.min_address_length,
    cd.cd_gender,
    STRING_AGG(DISTINCT cd.education_status) AS education_level,
    STRING_AGG(DISTINCT cd.credit_rating) AS credit_ratings
FROM 
    address_metrics a
JOIN 
    customer_demographics cd ON a.city_count > 100
GROUP BY 
    a.sanitized_city, a.city_count, a.avg_address_length, a.max_address_length, a.min_address_length, cd.cd_gender
ORDER BY 
    a.city_count DESC, a.sanitized_city;
