
WITH String_Benchmarks AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        UPPER(c.c_first_name) AS upper_first_name,
        LOWER(c.c_last_name) AS lower_last_name,
        SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_prefix,
        TRIM(c.c_email_address) AS trimmed_email,
        REPLACE(c.c_email_address, '.', ' ') AS no_dot_email,
        CONCAT('Customer: ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS formatted_name,
        REGEXP_REPLACE(c.c_email_address, '[^a-zA-Z0-9]', '') AS sanitized_email
    FROM 
        customer c
    WHERE 
        c.c_birth_year >= 1990
),
String_Aggregates AS (
    SELECT 
        COUNT(*) AS total_customers,
        AVG(first_name_length) AS avg_first_name_length,
        AVG(last_name_length) AS avg_last_name_length,
        COUNT(DISTINCT email_prefix) AS unique_email_prefixes
    FROM 
        String_Benchmarks
)
SELECT 
    *,
    (SELECT COUNT(*) FROM String_Benchmarks) AS benchmark_records,
    (SELECT AVG(LENGTH(full_name)) FROM String_Benchmarks) AS avg_full_name_length,
    (SELECT COUNT(DISTINCT upper_first_name) FROM String_Benchmarks) AS unique_upper_first_names
FROM 
    String_Aggregates;
