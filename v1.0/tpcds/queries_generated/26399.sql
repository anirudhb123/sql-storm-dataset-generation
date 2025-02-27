
WITH StringManipulation AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(CONCAT(c.c_first_name, '.', c.c_last_name, '@example.com')) AS email_variation,
        UPPER(w.w_warehouse_name) AS warehouse_name_upper,
        TRIM(REPLACE(c.ca_street_name, 'St', 'Street')) AS formatted_street_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        warehouse w ON ca.ca_address_sk = w.w_warehouse_sk
)
SELECT 
    full_name,
    email_variation,
    warehouse_name_upper,
    formatted_street_name
FROM 
    StringManipulation
WHERE 
    full_name LIKE 'Mr.%'
ORDER BY 
    full_name ASC
LIMIT 100;
