
WITH RankedAddresses AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS addr_rank
    FROM 
        customer_address
),
TopCities AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        RankedAddresses
    GROUP BY 
        ca_city, ca_state
    HAVING address_count > 10
),
FilteredAddresses AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.full_address
    FROM 
        RankedAddresses a
    JOIN 
        TopCities t ON a.ca_city = t.ca_city AND a.ca_state = t.ca_state
)
SELECT 
    fa.ca_city,
    fa.ca_state,
    fa.full_address,
    REPLACE(REPLACE(fa.full_address, ' ', '%20'), ',', '%2C') AS encoded_address
FROM 
    FilteredAddresses fa
WHERE 
    LENGTH(fa.full_address) > 30
ORDER BY 
    fa.ca_city, fa.ca_state, fa.full_address;
