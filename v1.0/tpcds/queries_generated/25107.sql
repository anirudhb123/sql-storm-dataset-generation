
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS city_state_rank
    FROM 
        customer_address
),
MaxRankedAddresses AS (
    SELECT 
        ca_city,
        ca_state,
        MAX(city_state_rank) AS max_rank
    FROM 
        RankedAddresses
    GROUP BY 
        ca_city, ca_state
),
AddressDetails AS (
    SELECT 
        ra.ca_address_sk,
        ra.full_address,
        ra.ca_city,
        ra.ca_state
    FROM 
        RankedAddresses ra
    JOIN 
        MaxRankedAddresses mra ON ra.ca_city = mra.ca_city AND ra.ca_state = mra.ca_state AND ra.city_state_rank = mra.max_rank
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    LISTAGG(ad.full_address, '; ') WITHIN GROUP (ORDER BY ad.full_address) AS concatenated_addresses,
    COUNT(*) AS address_count
FROM 
    AddressDetails ad
GROUP BY 
    ad.ca_city, ad.ca_state
ORDER BY 
    ad.ca_city, ad.ca_state;
