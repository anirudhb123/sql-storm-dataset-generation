
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
TopCities AS (
    SELECT 
        ca_city,
        total_addresses,
        unique_addresses,
        RANK() OVER (ORDER BY total_addresses DESC) AS city_rank
    FROM 
        AddressStats
)
SELECT 
    city_rank,
    ca_city,
    total_addresses,
    unique_addresses
FROM 
    TopCities
WHERE 
    city_rank <= 10
ORDER BY 
    city_rank;
