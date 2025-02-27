
WITH process_data AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_last_name
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_last_name
            ELSE c.c_last_name 
        END AS salutation,
        LENGTH(c.c_email_address) AS email_length,
        UPPER(ca.ca_city) AS city_upper,
        LOWER(ca.ca_state) AS state_lower
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_country LIKE '%United States%'
    ORDER BY 
        c.c_last_name, c.c_first_name
)
SELECT 
    process_data.*,
    CHAR_LENGTH(full_name) AS full_name_length,
    REPLACE(REPLACE(full_name, ' ', ''), '.', '') AS sanitized_full_name
FROM 
    process_data
WHERE 
    email_length > 0
HAVING 
    full_name_length > 10
LIMIT 100;
