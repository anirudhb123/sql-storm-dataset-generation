
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        LENGTH(ca_street_name) AS street_name_length,
        COALESCE(NULLIF(ca_suite_number, ''), 'N/A') AS suite_info,
        COUNT(*) OVER (PARTITION BY ca_city, ca_state) AS city_state_count
    FROM 
        customer_address
),
CityStateDetails AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS total_addresses,
        AVG(street_name_length) AS avg_street_length,
        LISTAGG(DISTINCT suite_info, ', ') AS suites_available
    FROM 
        RankedAddresses
    WHERE
        street_name_length > 0
    GROUP BY 
        ca_state, ca_city, street_name_length
)
SELECT 
    ca_state,
    ca_city,
    total_addresses,
    avg_street_length,
    suites_available,
    CASE 
        WHEN total_addresses > 100 THEN 'High Density'
        WHEN total_addresses BETWEEN 50 AND 100 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS address_density
FROM 
    CityStateDetails
ORDER BY 
    ca_state, ca_city;
