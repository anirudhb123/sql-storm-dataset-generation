
WITH StringBenchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        UPPER(c.c_email_address) AS email_upper,
        LOWER(c.c_email_address) AS email_lower,
        SUBSTR(c.c_email_address, 1, 5) AS email_prefix,
        REPLACE(c.c_email_address, '@', '[at]') AS email_modified,
        COUNT(DISTINCT ca.ca_zip) OVER (PARTITION BY ca.ca_state) AS zip_count_per_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_state IS NOT NULL)
)
SELECT 
    ca_state,
    COUNT(*) AS customer_count,
    AVG(full_name_length) AS avg_full_name_length,
    COUNT(DISTINCT email_modified) AS unique_email_modified_count
FROM 
    StringBenchmark
GROUP BY 
    ca_state
ORDER BY 
    customer_count DESC;
