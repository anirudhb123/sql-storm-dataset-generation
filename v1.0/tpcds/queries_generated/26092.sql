
WITH Address_Analysis AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_name) AS cleaned_street_name,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_type)) AS full_address,
        LOWER(ca_city) AS normalized_city,
        UPPER(ca_state) AS normalized_state,
        REPLACE(ca_zip, '-', '') AS standardized_zip,
        ca_country
    FROM 
        customer_address
),
City_Stats AS (
    SELECT 
        normalized_city,
        COUNT(*) AS address_count,
        STRING_AGG(full_address, '; ') AS address_list
    FROM 
        Address_Analysis
    GROUP BY 
        normalized_city
),
State_Stats AS (
    SELECT 
        normalized_state,
        COUNT(DISTINCT normalized_city) AS unique_cities,
        SUM(address_count) AS total_addresses
    FROM 
        City_Stats
    JOIN Address_Analysis ON City_Stats.normalized_city = Address_Analysis.normalized_city
    GROUP BY 
        normalized_state
)
SELECT 
    normalized_state,
    unique_cities,
    total_addresses,
    GROUP_CONCAT(DISTINCT normalized_city ORDER BY normalized_city) AS cities_list
FROM 
    State_Stats
GROUP BY 
    normalized_state
ORDER BY 
    total_addresses DESC;
