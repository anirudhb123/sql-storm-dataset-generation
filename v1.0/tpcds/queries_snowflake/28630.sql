
WITH split_strings AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        LISTAGG(DISTINCT ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type, ', ') WITHIN GROUP (ORDER BY ca.ca_street_number) AS full_address,
        REGEXP_REPLACE(c.c_email_address, '@.*', '') AS username,
        LENGTH(c.c_first_name || ' ' || c.c_last_name) AS full_name_length
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
address_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.full_address,
        c.username,
        c.full_name_length,
        (SELECT COUNT(*) 
         FROM customer_address 
         WHERE ca_city = 'New York') AS ny_address_count
    FROM 
        split_strings c
)
SELECT 
    a.c_customer_sk,
    a.full_address,
    a.username,
    a.full_name_length,
    a.ny_address_count,
    CASE 
        WHEN a.full_name_length > 30 THEN 'Long Name'
        WHEN a.full_name_length BETWEEN 15 AND 30 THEN 'Medium Name'
        ELSE 'Short Name'
    END AS name_category
FROM 
    address_analysis a
WHERE 
    a.ny_address_count > 0
ORDER BY 
    a.full_name_length DESC;
