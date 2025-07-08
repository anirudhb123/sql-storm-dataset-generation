
WITH StringBenchmarks AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address, 1, 15) AS truncated_email,
        REPLACE(c.c_last_name, 'a', '@') AS obfuscated_last_name,
        LOWER(c.c_first_name) AS lower_first_name,
        UPPER(c.c_last_name) AS upper_last_name,
        LPAD(TO_VARCHAR(c.c_birth_day), 2, '0') || '-' || LPAD(TO_VARCHAR(c.c_birth_month), 2, '0') || '-' || TO_VARCHAR(c.c_birth_year) AS formatted_birthdate,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length
    FROM
        customer c
)
SELECT
    full_name, 
    truncated_email,
    obfuscated_last_name,
    lower_first_name,
    upper_last_name,
    formatted_birthdate,
    first_name_length,
    last_name_length
FROM 
    StringBenchmarks
WHERE 
    first_name_length > 5
ORDER BY 
    last_name_length DESC
LIMIT 100;
