
WITH string_benchmarks AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_street_number) AS street_number_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_country) AS lower_country,
        REGEXP_REPLACE(ca_street_name, '[^A-Za-z0-9 ]', '') AS sanitized_street_name
    FROM customer_address
), aggregated_metrics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(street_name_length) AS avg_street_name_length,
        AVG(street_number_length) AS avg_street_number_length,
        LISTAGG(full_address, '; ') AS all_addresses,
        LISTAGG(upper_city, '; ') AS all_upper_cities,
        LISTAGG(lower_country, '; ') AS all_lower_countries,
        LISTAGG(sanitized_street_name, '; ') AS all_sanitized_street_names
    FROM string_benchmarks
    GROUP BY ca_state
)
SELECT 
    ca_state,
    address_count,
    avg_street_name_length,
    avg_street_number_length,
    SPLIT_PART(all_addresses, '; ', 1) AS first_address,
    SPLIT_PART(all_upper_cities, '; ', 1) AS first_upper_city,
    SPLIT_PART(all_lower_countries, '; ', 1) AS first_lower_country
FROM aggregated_metrics
ORDER BY address_count DESC
LIMIT 10;
