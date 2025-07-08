
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
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
ProcessedData AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        LTRIM(RTRIM(full_name)) AS trimmed_name,
        REPLACE(full_name, ' ', '-') AS hyphenated_name,
        INITCAP(full_name) AS capitalized_name,
        LENGTH(full_name) AS name_length,
        CASE 
            WHEN SUBSTRING(full_name, 1, 1) = 'A' THEN 'Starts with A'
            ELSE 'Does not start with A'
        END AS name_a_indicator
    FROM 
        CustomerData
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS count,
    AVG(name_length) AS avg_name_length,
    COUNT(DISTINCT hyphenated_name) AS unique_hyphenated_names,
    LISTAGG(capitalized_name, ', ') AS capitalized_names_list
FROM 
    ProcessedData
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    cd_gender, cd_marital_status;
