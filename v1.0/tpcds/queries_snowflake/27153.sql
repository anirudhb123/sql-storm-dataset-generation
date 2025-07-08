
WITH ExpandedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || 
        COALESCE(' ' || ca_suite_number, '') AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(full_address, '; ') WITHIN GROUP (ORDER BY full_address) AS all_addresses
    FROM 
        ExpandedAddresses
    GROUP BY 
        ca_state
),
TopStates AS (
    SELECT 
        ca_state,
        address_count
    FROM 
        AddressCounts
    ORDER BY 
        address_count DESC
    LIMIT 5
)
SELECT 
    tc.ca_state,
    tc.address_count,
    'Top Addresses: ' || ac.all_addresses AS top_addresses
FROM 
    TopStates tc
JOIN 
    AddressCounts ac ON tc.ca_state = ac.ca_state;
