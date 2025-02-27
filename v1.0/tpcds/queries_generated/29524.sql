
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@example.com', '@test.com') AS modified_email,
        UPPER(c.c_first_name) AS upper_first_name,
        CONCAT(LEFT(c.c_first_name, 1), LOWER(SUBSTRING(c.c_last_name, 1, 3))) AS username,
        LENGTH(c.c_email_address) AS email_length,
        STRING_AGG(DISTINCT SUBSTRING(c.c_last_name, 1, 3), ', ') OVER (PARTITION BY c.c_current_hdemo_sk) AS last_name_prefixes
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND c.c_birth_year BETWEEN 1970 AND 1990
)
SELECT 
    full_name,
    modified_email,
    upper_first_name,
    username,
    email_length,
    last_name_prefixes
FROM 
    StringProcessing
ORDER BY 
    email_length DESC
LIMIT 100;
