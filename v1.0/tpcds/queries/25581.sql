
WITH RankedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY LENGTH(ca.ca_street_name) DESC) as street_length_rank
    FROM 
        customer_address ca
), 
FilteredAddresses AS (
    SELECT 
        ra.ca_address_sk,
        ra.ca_address_id,
        ra.ca_street_name,
        ra.ca_city,
        ra.ca_state
    FROM 
        RankedAddresses ra
    WHERE 
        ra.street_length_rank <= 10
)
SELECT 
    fa.ca_state,
    COUNT(*) AS address_count,
    STRING_AGG(fa.ca_city, ', ') AS cities_in_state,
    STRING_AGG(fa.ca_street_name, '; ') AS street_names
FROM 
    FilteredAddresses fa
GROUP BY 
    fa.ca_state
ORDER BY 
    address_count DESC;
