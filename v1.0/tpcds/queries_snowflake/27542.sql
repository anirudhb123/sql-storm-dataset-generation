
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city, ca_street_name) AS rank
    FROM customer_address
),
AddressStringAggregates AS (
    SELECT 
        ca_state,
        LISTAGG(CONCAT(ca_city, ': ', ca_street_name), '; ') WITHIN GROUP (ORDER BY ca_city, ca_street_name) AS city_street_list
    FROM RankedAddresses
    WHERE rank <= 5
    GROUP BY ca_state
),
CustomerAddressCount AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_state
)
SELECT 
    a.ca_state,
    a.city_street_list,
    c.address_count
FROM AddressStringAggregates a
JOIN CustomerAddressCount c ON a.ca_state = c.ca_state
ORDER BY c.address_count DESC;
