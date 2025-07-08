
WITH formatted_addresses AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), ''), ', ', 
               ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country
    FROM 
        customer_address
), address_statistics AS (
    SELECT 
        ca_country,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(full_address)) AS avg_address_length,
        MAX(LENGTH(full_address)) AS max_address_length,
        MIN(LENGTH(full_address)) AS min_address_length
    FROM 
        formatted_addresses
    GROUP BY 
        ca_country
), address_by_country AS (
    SELECT 
        ca_country,
        LISTAGG(full_address, '; ') AS all_addresses
    FROM 
        formatted_addresses
    GROUP BY 
        ca_country
)
SELECT 
    a.ca_country,
    a.total_addresses,
    a.avg_address_length,
    a.max_address_length,
    a.min_address_length,
    b.all_addresses
FROM 
    address_statistics a
JOIN 
    address_by_country b ON a.ca_country = b.ca_country
ORDER BY 
    a.total_addresses DESC;
