
WITH String_Processing AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name,
        CONCAT(LOWER(c.c_first_name), ' ', UPPER(c.c_last_name)) AS formatted_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        SUBSTRING_INDEX(c.c_email_address, '@', -1) AS email_domain,
        UPPER(SUBSTRING(c.c_email_address, 1, 5)) AS email_prefix
    FROM 
        customer c
    WHERE 
        c.c_birth_month BETWEEN 1 AND 12
)
SELECT 
    formatted_name,
    name_length,
    email_domain,
    email_prefix
FROM 
    String_Processing
WHERE 
    LENGTH(formatted_name) > 20
ORDER BY 
    name_length DESC
LIMIT 100;
