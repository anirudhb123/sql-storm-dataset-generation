
WITH processed_addresses AS (
    SELECT 
        ca_city,
        ca_state,
        INITCAP(ca_street_name) AS formatted_street_name,
        TRIM(ca_street_number) AS cleaned_street_number,
        CONCAT(TRIM(ca_street_number), ' ', INITCAP(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        REGEXP_REPLACE(ca_suite_number, '[^0-9]', '') AS numeric_suite_number
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
)
SELECT 
    ca_state,
    COUNT(*) AS address_count,
    AVG(street_name_length) AS avg_street_name_length,
    LISTAGG(full_address, '; ') AS unique_addresses
FROM 
    processed_addresses
GROUP BY 
    ca_state
ORDER BY 
    address_count DESC;
