
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
StringProcessingBenchmark AS (
    SELECT 
        full_name,
        UPPER(full_name) AS upper_case_name,
        LOWER(full_name) AS lower_case_name,
        LENGTH(full_name) AS name_length,
        CHAR_LENGTH(full_name) AS char_length,
        REPLACE(full_name, ' ', '-') AS dashed_name,
        TRIM(full_name) AS trimmed_name,
        SUBSTRING(full_name FROM 1 FOR 10) AS name_substring,
        POSITION(' ' IN full_name) AS first_space_position
    FROM CustomerDetails
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(name_length) AS avg_name_length,
    MAX(upper_case_name) AS max_upper_case_name,
    MIN(lower_case_name) AS min_lower_case_name,
    SUM(CASE WHEN first_space_position > 0 THEN 1 ELSE 0 END) AS name_with_space,
    SUM(CASE WHEN trimmed_name <> full_name THEN 1 ELSE 0 END) AS names_trimmed
FROM StringProcessingBenchmark
JOIN customer_demographics cd ON cd.cd_demo_sk = (
    SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = StringProcessingBenchmark.c_customer_sk
)
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY customer_count DESC;
