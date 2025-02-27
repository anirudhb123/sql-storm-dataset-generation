
WITH StringBenchmark AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        UPPER(c.c_email_address) AS email_upper,
        DECRYPT(c.c_login) AS decrypted_login,
        SUBSTR(ca.ca_street_name, 1, 10) AS short_street_name,
        LENGTH(ca.ca_zip) AS zip_length,
        REGEXP_REPLACE(c.c_email_address, '@.*$', '@example.com') AS replaced_email
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        LENGTH(c.c_first_name) > 5
        AND ca.ca_state = 'CA'
)
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT full_name) AS unique_names,
    COUNT(DISTINCT email_upper) AS unique_emails,
    SUM(zip_length) AS total_zip_length,
    COUNT(CASE WHEN replaced_email LIKE '%@example.com' THEN 1 END) AS email_replaced_count
FROM 
    StringBenchmark;
