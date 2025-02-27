
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END,
               ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip), ', ', TRIM(ca_country)) AS full_address
    FROM 
        customer_address
),
substring_count AS (
    SELECT 
        SUBSTRING(full_address FROM 1 FOR 20) AS address_substring,
        COUNT(*) AS address_count
    FROM 
        processed_addresses
    GROUP BY 
        address_substring
),
address_lengths AS (
    SELECT 
        CHAR_LENGTH(full_address) AS address_length,
        COUNT(*) AS length_count
    FROM 
        processed_addresses
    GROUP BY 
        address_length
),
address_grouped AS (
    SELECT 
        LENGTH, 
        SUM(address_count) AS total_addresses
    FROM 
        substring_count
    JOIN 
        address_lengths ON substring_count.address_substring LIKE CONCAT('%', TRIM(CAST(address_lengths.address_length AS VARCHAR)), '%')
    GROUP BY 
        address_length
)
SELECT 
    AVG(address_length) AS avg_address_length,
    SUM(total_addresses) AS total_full_addresses,
    COUNT(DISTINCT ca_address_sk) AS unique_addresses
FROM 
    processed_addresses 
JOIN 
    address_grouped ON TRUE
WHERE 
    ca_country = 'USA' 
GROUP BY 
    ca_state
ORDER BY 
    avg_address_length DESC;
