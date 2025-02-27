
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(REPLACE(c.email_address, '@', '_at_'), '.', '_dot_') AS modified_email,
        LENGTH(c.email_address) AS email_length,
        SUBSTRING(c.c_first_name, 1, 3) AS first_name_prefix,
        UPPER(SUBSTRING(c.c_last_name, 1, 3)) AS last_name_prefix,
        CASE 
            WHEN c.c_birth_year BETWEEN 1990 AND 1999 THEN 'Millennial'
            WHEN c.c_birth_year BETWEEN 1980 AND 1989 THEN 'Gen X'
            WHEN c.c_birth_year BETWEEN 1970 AND 1979 THEN 'Gen Y'
            ELSE 'Other'
        END AS generation
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city LIKE '%York%'
    ORDER BY 
        email_length DESC
)
SELECT 
    full_name, 
    modified_email, 
    email_length, 
    first_name_prefix, 
    last_name_prefix, 
    generation 
FROM 
    StringProcessing
WHERE 
    generation = 'Millennial'
LIMIT 100;
