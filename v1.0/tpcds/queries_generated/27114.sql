
WITH StringProcessing AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUBSTRING(c.c_email_address FROM 1 FOR 10) AS email_prefix,
        UPPER(DISTINCT ca.ca_city) AS upper_city,
        LENGTH(ca.ca_street_name) AS street_name_length,
        REGEXP_REPLACE(ca.ca_street_name, '[^a-zA-Z ]', '') AS cleaned_street_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
)
SELECT 
    full_name,
    email_prefix,
    upper_city,
    street_name_length,
    cleaned_street_name
FROM 
    StringProcessing
WHERE 
    street_name_length > 5
ORDER BY 
    upper_city DESC;
