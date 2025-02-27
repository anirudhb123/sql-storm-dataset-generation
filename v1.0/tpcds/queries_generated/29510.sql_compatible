
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS city_rank
    FROM customer_address
    WHERE ca_country = 'USA'
),
AddressStatistics AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses, 
        AVG(city_rank) AS avg_rank
    FROM RankedAddresses
    GROUP BY ca_state
),
StringProcessed AS (
    SELECT 
        ca_state,
        STRING_AGG(ca_city || ':' || total_addresses || ' (' || avg_rank || ')', ', ') AS city_summary
    FROM AddressStatistics
    GROUP BY ca_state
)
SELECT
    ca_state,
    city_summary
FROM StringProcessed
ORDER BY ca_state;
