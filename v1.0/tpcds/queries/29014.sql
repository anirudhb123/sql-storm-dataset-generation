
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ca_street_name,
        ROW_NUMBER() OVER(PARTITION BY ca_city ORDER BY LENGTH(ca_street_name) DESC) as city_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
AddressSummary AS (
    SELECT 
        ca_city,
        COUNT(*) as address_count,
        MIN(ca_state) as min_state,
        MAX(ca_state) as max_state,
        STRING_AGG(DISTINCT ca_country, ', ') as unique_countries
    FROM 
        RankedAddresses
    GROUP BY 
        ca_city
    HAVING 
        COUNT(*) > 5
)
SELECT 
    a.ca_city,
    a.address_count,
    a.min_state,
    a.max_state,
    a.unique_countries,
    CONCAT('City: ', a.ca_city, ', States: ', a.min_state, ' to ', a.max_state, ', Countries: ', a.unique_countries) as address_info
FROM 
    AddressSummary a
ORDER BY 
    a.address_count DESC;
