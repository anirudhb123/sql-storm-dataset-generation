
WITH base_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(SUBSTRING_INDEX(c.c_email_address, '@', 1), 'unknown') AS email_user,
        LENGTH(c.c_email_address) AS email_length,
        REPLACE(COALESCE(ca.ca_zip, '00000'), '0', '') AS zip_digits
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    email_user,
    email_length,
    zip_digits,
    CASE 
        WHEN email_length > 20 THEN 'Long Email'
        ELSE 'Short Email'
    END AS email_category,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male'
        WHEN cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description
FROM base_data
WHERE LENGTH(full_name) > 15
AND (cd_marital_status = 'M' OR cd_marital_status = 'S')
ORDER BY ca_city, email_length DESC;
