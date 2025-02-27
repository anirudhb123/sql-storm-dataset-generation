
WITH StringManipulations AS (
    SELECT 
        ca_address_id,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_city) AS lower_city,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(ca_zip, '-', '') AS sanitized_zip,
        SUBSTRING(ca_country FROM 1 FOR 3) AS country_code
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'TX') AND 
        ca_zip IS NOT NULL
)
SELECT 
    COUNT(*) AS records_processed,
    AVG(street_name_length) AS avg_street_name_length,
    MAX(upper_street_name) AS max_upper_street_name,
    MIN(lower_city) AS min_lower_city,
    STRING_AGG(full_address, '; ') AS full_addresses_sample,
    COUNT(DISTINCT sanitized_zip) AS unique_zip_codes,
    STRING_AGG(country_code, ', ') AS sample_country_codes
FROM 
    StringManipulations;
