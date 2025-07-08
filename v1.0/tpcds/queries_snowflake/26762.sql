
WITH StringBench AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length,
        SUBSTR(ca_city, 1, 5) AS city_prefix,
        UPPER(ca_country) AS country_upper,
        LOWER(ca_state) AS state_lower,
        MD5(CONCAT(ca_address_id, CAST(ca_zip AS CHAR))) AS address_checksum
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL 
        AND ca_country IS NOT NULL
)
SELECT 
    city_prefix,
    COUNT(*) AS address_count,
    AVG(address_length) AS avg_address_length,
    COUNT(DISTINCT country_upper) AS unique_countries,
    MIN(address_checksum) AS min_checksum,
    MAX(address_checksum) AS max_checksum
FROM 
    StringBench
GROUP BY 
    city_prefix
ORDER BY 
    address_count DESC
LIMIT 10;
