
WITH StringBenchmark AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        REPLACE(c.c_email_address, '@', '[at]') AS masked_email,
        LOWER(c.c_last_name) AS lower_last_name,
        UPPER(c.c_first_name) AS upper_first_name,
        LEFT(c.ca_address_id, 5) AS address_prefix,
        RIGHT(c.ca_zip, 5) AS zip_suffix,
        SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
        POSITION('a' IN c.c_first_name) AS position_a,
        TRIM(c.c_first_name) AS trimmed_first_name
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL
)
SELECT 
    DISTINCT ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(full_name_length) AS avg_full_name_length,
    COUNT(CASE WHEN position_a > 0 THEN 1 END) AS count_of_a,
    STRING_AGG(masked_email, ', ') AS masked_emails
FROM 
    StringBenchmark
GROUP BY 
    ca_state
ORDER BY 
    unique_customers DESC;
