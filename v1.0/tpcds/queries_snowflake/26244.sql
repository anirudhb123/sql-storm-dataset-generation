
WITH string_benchmark AS (
    SELECT 
        ca.ca_city AS city,
        ca.ca_state AS state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        SUBSTRING(ca.ca_country, 1, 3) AS country_prefix,
        LENGTH(ca.ca_zip) AS zip_length,
        LOWER(ca.ca_city) AS city_lower,
        UPPER(ca.ca_state) AS state_upper,
        REPLACE(ca.ca_street_name, 'Street', 'St') AS street_abbreviation
    FROM customer_address ca
    WHERE ca.ca_city IS NOT NULL
), aggregated_string_benchmark AS (
    SELECT 
        city_lower,
        COUNT(*) AS address_count,
        MAX(zip_length) AS max_zip_length,
        MIN(zip_length) AS min_zip_length,
        LISTAGG(street_abbreviation, ', ') WITHIN GROUP (ORDER BY street_abbreviation) AS all_streets
    FROM string_benchmark
    GROUP BY city_lower
)
SELECT 
    city_lower,
    address_count,
    max_zip_length,
    min_zip_length,
    all_streets
FROM aggregated_string_benchmark
WHERE address_count > 10
ORDER BY address_count DESC;
