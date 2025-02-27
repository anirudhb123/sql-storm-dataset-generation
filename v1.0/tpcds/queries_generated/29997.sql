
WITH string_benchmark AS (
    SELECT 
        ca.address_sk,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        LENGTH(ca.street_name) AS name_length,
        UPPER(ca.city) AS uppercase_city,
        LOWER(ca.state) AS lowercase_state,
        REPLACE(ca.zip, '-', '') AS sanitized_zip,
        SUBSTRING(ca.country FROM 1 FOR 3) AS country_code,
        POSITION('New' IN ca.street_name) AS position_of_keyword
    FROM 
        customer_address ca
    WHERE 
        ca.street_name IS NOT NULL
)

SELECT 
    COUNT(*) AS total_addresses,
    AVG(name_length) AS avg_name_length,
    COUNT(DISTINCT uppercase_city) AS unique_cities,
    COUNT(DISTINCT sanitized_zip) AS unique_zips,
    SUM(CASE WHEN position_of_keyword > 0 THEN 1 ELSE 0 END) AS keyword_occurrences
FROM 
    string_benchmark
HAVING 
    AVG(name_length) > 20
ORDER BY 
    total_addresses DESC;
