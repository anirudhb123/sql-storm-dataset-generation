
WITH String_Benchmark AS (
    SELECT 
        DISTINCT 
        c.c_first_name,
        c.c_last_name,
        CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
        LOWER(c.c_email_address) AS email_lower,
        UPPER(c.c_email_address) AS email_upper,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTRING(c.c_email_address, 1, 10) AS email_partial,
        REPLACE(c.c_email_address, '@', '[at]') AS email_replaced,
        CONCAT(c.c_city, ', ', c.ca_state) AS location,
        LPAD(c.c_birth_month, 2, '0') AS birth_month,
        LPAD(c.c_birth_day, 2, '0') AS birth_day,
        LPAD(c.c_birth_year, 4, '0') AS birth_year_formatted,
        TRIM(c.c_first_name) AS first_name_trimmed
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_last_review_date_sk IS NOT NULL
)
SELECT 
    LENGTH(full_name) AS full_name_length,
    COUNT(*) AS total_customers,
    AVG(email_length) AS average_email_length,
    MAX(email_length) AS max_email_length,
    MIN(email_length) AS min_email_length
FROM 
    String_Benchmark
GROUP BY 
    full_name_length
ORDER BY 
    full_name_length DESC;
