
WITH concatenated_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END,
               ', ', ca_city, ', ', ca_county, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
    FROM 
        customer_address
),
address_stats AS (
    SELECT 
        LENGTH(full_address) AS address_length,
        SUBSTRING(full_address, POSITION(',' IN full_address) + 1) AS details_after_comma,
        COUNT(*) AS address_count
    FROM 
        concatenated_addresses
    GROUP BY 
        LENGTH(full_address), details_after_comma
),
stats_summary AS (
    SELECT 
        MIN(address_length) AS min_address_length,
        MAX(address_length) AS max_address_length,
        AVG(address_length) AS avg_address_length,
        SUM(address_count) AS total_addresses
    FROM 
        address_stats
)
SELECT 
    s.min_address_length,
    s.max_address_length,
    s.avg_address_length,
    s.total_addresses,
    CONCAT_WS(', ', STRING_AGG(details_after_comma, '; ')) AS details_after_comma_summary
FROM 
    stats_summary s
JOIN 
    address_stats a ON a.address_length = s.avg_address_length
GROUP BY 
    s.min_address_length, s.max_address_length, s.avg_address_length, s.total_addresses;
