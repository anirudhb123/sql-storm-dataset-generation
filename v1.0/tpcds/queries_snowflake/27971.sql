
WITH String_Processing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        LOWER(c.c_email_address) AS lower_email,
        UPPER(c.c_email_address) AS upper_email,
        REPLACE(c.c_email_address, '@', '[at]') AS email_replaced,
        LEFT(c.c_email_address, 5) AS email_prefix,
        RIGHT(c.c_email_address, 3) AS email_suffix,
        POSITION('.' IN c.c_email_address) AS first_dot_position,
        REGEXP_REPLACE(c.c_email_address, '[^a-zA-Z0-9]', '') AS email_alnum
    FROM
        customer c
)
SELECT 
    MAX(email_length) AS max_email_length,
    MIN(email_length) AS min_email_length,
    AVG(email_length) AS avg_email_length,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    LISTAGG(full_name, '; ') AS all_full_names
FROM 
    String_Processing
WHERE 
    LOWER(lower_email) LIKE '%@domain.com'
GROUP BY 
    email_prefix, email_suffix, full_name
ORDER BY 
    max_email_length DESC
LIMIT 100;
