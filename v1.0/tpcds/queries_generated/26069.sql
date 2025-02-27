
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
string_benchmark AS (
    SELECT 
        c.customer_sk,
        LENGTH(full_name) AS name_length,
        UPPER(full_name) AS upper_full_name,
        LOWER(full_name) AS lower_full_name,
        REPLACE(full_name, ' ', '-') AS hyphenated_name,
        CONCAT_WS(', ', ca_city, ca_state, ca_country) AS full_address,
        SUBSTR(full_name, 1, 10) AS name_substr,
        REGEXP_REPLACE(full_name, '[^A-Za-z]', '') AS alpha_only_name,
        CHAR_LENGTH(full_name) AS char_length
    FROM 
        customer_info c
)
SELECT 
    COUNT(*) AS total_customers,
    AVG(name_length) AS avg_name_length,
    COUNT(DISTINCT cd_gender) AS distinct_genders,
    COUNT(DISTINCT cd_marital_status) AS distinct_marital_status,
    COUNT(DISTINCT UPPER(cd_education_status)) AS distinct_upper_education_status,
    STRING_AGG(DISTINCT full_address, ', ') AS unique_addresses
FROM 
    string_benchmark;
