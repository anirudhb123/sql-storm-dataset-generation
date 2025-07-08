
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_city) AS city_rank
    FROM 
        customer_address
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(full_address, '; ') AS all_addresses
    FROM 
        RankedAddresses
    WHERE 
        city_rank <= 10
    GROUP BY 
        ca_state
)
SELECT 
    sa.ca_state,
    sa.address_count,
    CONCAT('Top addresses in ', sa.ca_state, ': ', sa.all_addresses) AS address_summary
FROM 
    AddressStats sa
WHERE 
    sa.address_count > 0
ORDER BY 
    sa.ca_state;
