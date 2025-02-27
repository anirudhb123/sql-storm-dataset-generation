
WITH RankedAddresses AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_country) AS city_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
AddressSummary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_country, ' (', city_rank, ')') ORDER BY ca_country) AS country_list
    FROM 
        RankedAddresses
    GROUP BY 
        ca_city
)
SELECT 
    a.ca_city,
    a.address_count,
    a.country_list
FROM 
    AddressSummary a
JOIN 
    customer_demographics cd ON a.address_count > cd.cd_dep_count
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    a.address_count DESC
LIMIT 10;
