
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        LOWER(TRIM(ca_city)) AS normalized_city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM 
        customer_address
),
city_summary AS (
    SELECT 
        normalized_city, 
        COUNT(*) as address_count,
        COUNT(DISTINCT state) as unique_states,
        COUNT(DISTINCT zip) as unique_zips
    FROM 
        processed_addresses
    GROUP BY 
        normalized_city
),
state_summary AS (
    SELECT 
        state, 
        COUNT(*) as address_count,
        LISTAGG(normalized_city, ', ') WITHIN GROUP (ORDER BY normalized_city) AS cities
    FROM 
        processed_addresses
    GROUP BY 
        state
)
SELECT 
    ca.full_address,
    cs.address_count AS city_address_count,
    ss.address_count AS state_address_count,
    ss.cities AS cities_in_state
FROM 
    processed_addresses ca
JOIN 
    city_summary cs ON LOWER(ca.normalized_city) = LOWER(cs.normalized_city)
JOIN 
    state_summary ss ON ca.state = ss.state
WHERE 
    cs.address_count > 1 
    AND ss.address_count > 2
ORDER BY 
    ss.address_count DESC, 
    cs.address_count DESC, 
    ca.full_address
LIMIT 100;
