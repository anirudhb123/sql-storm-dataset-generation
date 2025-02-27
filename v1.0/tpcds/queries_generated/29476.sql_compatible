
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        LENGTH(ca_street_name) > 10
),
CityCount AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_city) AS unique_city_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
StreetStatistics AS (
    SELECT 
        ra.ca_state,
        MAX(LENGTH(ra.ca_street_name)) AS max_street_length,
        MIN(LENGTH(ra.ca_street_name)) AS min_street_length,
        AVG(LENGTH(ra.ca_street_name)) AS avg_street_length
    FROM 
        RankedAddresses ra
    GROUP BY 
        ra.ca_state
)
SELECT 
    cs.ca_state,
    cs.unique_city_count,
    ss.max_street_length,
    ss.min_street_length,
    ss.avg_street_length,
    STRING_AGG(DISTINCT CONCAT(ra.ca_street_name, ' ', ra.ca_city), ', ') AS street_city_combination
FROM 
    CityCount cs
JOIN 
    StreetStatistics ss ON cs.ca_state = ss.ca_state
JOIN 
    RankedAddresses ra ON cs.ca_state = ra.ca_state
WHERE 
    ra.rn <= 5  
GROUP BY 
    cs.ca_state, cs.unique_city_count, ss.max_street_length, ss.min_street_length, ss.avg_street_length
ORDER BY 
    cs.ca_state;
