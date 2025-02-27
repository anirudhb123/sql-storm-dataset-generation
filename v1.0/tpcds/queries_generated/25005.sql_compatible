
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        INITCAP(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(ca_city) AS city_lowercase,
        UPPER(ca_state) AS state_uppercase,
        CONCAT(ca_zip, ', ', ca_country) AS zip_country
    FROM customer_address
),
address_stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT city_lowercase) AS unique_cities,
        STRING_AGG(full_address, '; ') AS all_full_addresses
    FROM processed_addresses
    GROUP BY ca_state
)
SELECT 
    state_uppercase,
    total_addresses,
    unique_cities,
    LENGTH(all_full_addresses) AS total_address_length,
    (SELECT COUNT(*) FROM processed_addresses) AS total_processed_addresses
FROM address_stats
ORDER BY total_addresses DESC;
