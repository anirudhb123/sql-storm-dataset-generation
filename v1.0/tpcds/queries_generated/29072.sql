
WITH String_Benchmark AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        SUBSTRING(c.c_email_address, 1, 20) AS email_prefix,
        REPLACE(c.c_last_name, 'a', '@') AS modified_last_name,
        CHAR_LENGTH(c.c_city) AS city_length,
        UPPER(c.c_country) AS country_upper,
        LOWER(c.c_first_name) AS first_name_lower,
        REGEXP_REPLACE(c.c_email_address, '[^a-zA-Z0-9]', '') AS cleaned_email
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        LENGTH(c.c_first_name) > 0
    ORDER BY 
        full_name_length DESC
)
SELECT 
    AVG(full_name_length) AS avg_length,
    COUNT(DISTINCT email_prefix) AS distinct_email_prefix_count,
    SUM(CASE WHEN modified_last_name LIKE '%@%' THEN 1 ELSE 0 END) AS special_last_name_count,
    MAX(city_length) AS max_city_length,
    MIN(city_length) AS min_city_length,
    COUNT(*) AS total_records
FROM 
    String_Benchmark;
