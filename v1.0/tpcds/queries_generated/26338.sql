
WITH StringBenchmark AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_first_name) AS first_name_length,
        LENGTH(c.c_last_name) AS last_name_length,
        SUBSTRING_INDEX(c.c_email_address, '@', 1) AS email_prefix,
        UPPER(c.c_last_name) AS upper_last_name,
        REPLACE(UPPER(c.c_email_address), '.', '-') AS modified_email,
        COUNT(*) OVER () AS total_records
    FROM 
        customer c
    WHERE 
        c.c_first_name IS NOT NULL 
        AND c.c_last_name IS NOT NULL 
)
SELECT 
    full_name,
    first_name_length,
    last_name_length,
    email_prefix,
    upper_last_name,
    modified_email,
    total_records
FROM 
    StringBenchmark
WHERE 
    first_name_length > 3
ORDER BY 
    last_name_length DESC, full_name ASC
LIMIT 100;
