
WITH string_benchmark AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        SUBSTRING(ca.ca_street_name FROM 1 FOR 10) AS street_name_sub,
        LENGTH(ca.ca_street_name) AS street_name_length,
        REPLACE(LOWER(ca.ca_city), ' ', '-') AS city_slug,
        CHAR_LENGTH(ca.ca_street_name) AS char_length
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
),
stats AS (
    SELECT
        AVG(street_name_length) AS avg_length,
        COUNT(DISTINCT city_slug) AS unique_cities,
        MAX(char_length) AS max_char_length,
        MIN(char_length) AS min_char_length
    FROM 
        string_benchmark
)
SELECT 
    sb.full_address,
    s.avg_length,
    s.unique_cities,
    s.max_char_length,
    s.min_char_length
FROM 
    string_benchmark sb
CROSS JOIN 
    stats s
ORDER BY 
    sb.char_length DESC 
LIMIT 100;
