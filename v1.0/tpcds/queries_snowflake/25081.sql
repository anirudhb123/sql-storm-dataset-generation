
WITH StringProcessingResults AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_city) AS lower_city,
        LENGTH(ca_street_type) AS street_type_length,
        RTRIM(ca_suite_number) AS trimmed_suite_number,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        SUBSTRING(ca_country, 1, 3) AS country_abbr
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
)
SELECT 
    COUNT(*) AS total_records,
    MAX(street_type_length) AS max_street_type_length,
    MIN(street_type_length) AS min_street_type_length,
    AVG(street_type_length) AS avg_street_type_length,
    LISTAGG(upper_street_name, ', ') WITHIN GROUP (ORDER BY upper_street_name) AS combined_upper_street_names,
    LISTAGG(lower_city, ', ') WITHIN GROUP (ORDER BY lower_city) AS combined_lower_cities,
    LISTAGG(trimmed_suite_number, ', ') WITHIN GROUP (ORDER BY trimmed_suite_number) AS combined_trimmed_suites,
    LISTAGG(full_address, '; ') WITHIN GROUP (ORDER BY full_address) AS all_full_addresses,
    COUNT(DISTINCT country_abbr) AS distinct_country_abbr_count
FROM 
    StringProcessingResults;
