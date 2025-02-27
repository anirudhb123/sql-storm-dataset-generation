
WITH StringMetrics AS (
    SELECT 
        ca_address_sk,
        LOWER(ca_street_name) AS street_name_lowercase,
        UPPER(ca_city) AS city_uppercase,
        LENGTH(ca_street_name) AS street_name_length,
        CHAR_LENGTH(ca_street_name) AS street_name_char_length,
        CONCAT(ca_street_name, ', ', ca_city, ', ', ca_state) AS full_address,
        REPLACE(ca_zip, '-', '') AS cleaned_zip,
        SPLIT_PART(ca_street_name, ' ', 1) AS street_first_word
    FROM 
        customer_address
),
BenchmarkStats AS (
    SELECT 
        AVG(street_name_length) AS avg_street_name_length,
        MAX(city_uppercase) AS max_city_uppercase,
        MIN(street_name_length) AS min_street_name_length,
        COUNT(DISTINCT street_first_word) AS unique_street_first_words,
        COUNT(DISTINCT cleaned_zip) AS unique_zips
    FROM 
        StringMetrics
)
SELECT 
    bs.*, 
    SUM(sm_full_address) OVER() AS total_addresses_processed
FROM 
    BenchmarkStats bs;
