
WITH string_benchmark AS (
    SELECT
        ca.city AS address_city,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        REPLACE(c.c_email_address, '@', '[at]') AS sanitized_email,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || c.c_first_name
            ELSE c.c_first_name
        END AS salutation,
        LENGTH(ca.ca_street_name) AS street_name_length,
        SUBSTRING(ca.ca_street_name FROM 1 FOR 10) AS short_street_name,
        UPPER(cd.cd_marital_status) AS marital_status_upper,
        LOWER(cd.cd_education_status) AS education_status_lower
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ca.ca_city IS NOT NULL AND c.c_email_address IS NOT NULL
)
SELECT 
    address_city,
    customer_name,
    sanitized_email,
    salutation,
    street_name_length,
    short_street_name,
    marital_status_upper,
    education_status_lower
FROM 
    string_benchmark
ORDER BY 
    address_city, customer_name;
