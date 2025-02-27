
WITH StringBenchmark AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_uppercase,
        LOWER(ca_street_name) AS street_name_lowercase,
        REPLACE(ca_street_name, ' ', '-') AS street_name_hyphenated,
        SUBSTRING_INDEX(ca_street_name, ' ', 1) AS first_word_street_name
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
BenchmarkResults AS (
    SELECT 
        full_address,
        street_name_length,
        city_uppercase,
        street_name_lowercase,
        street_name_hyphenated,
        first_word_street_name,
        ROW_NUMBER() OVER (ORDER BY street_name_length DESC) AS row_num
    FROM 
        StringBenchmark
)
SELECT 
    full_address,
    street_name_length,
    city_uppercase,
    street_name_lowercase,
    street_name_hyphenated,
    first_word_street_name 
FROM 
    BenchmarkResults
WHERE 
    row_num <= 10;
