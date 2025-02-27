
WITH processed_addresses AS (
    SELECT 
        LOWER(TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip))) AS complete_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip
),
address_summary AS (
    SELECT 
        complete_address,
        CASE 
            WHEN address_count > 1 THEN 'Duplicate'
            ELSE 'Unique'
        END AS address_type
    FROM 
        processed_addresses
)
SELECT 
    address_type,
    COUNT(*) AS total_addresses,
    STRING_AGG(complete_address, '; ') AS aggregated_addresses
FROM 
    address_summary
GROUP BY 
    address_type
ORDER BY 
    total_addresses DESC;
