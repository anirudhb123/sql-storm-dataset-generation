
WITH address_info AS (
    SELECT
        ca_city,
        ca_state,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM customer_address
),
demographic_info AS (
    SELECT
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_description,
        cd_marital_status,
        cd_education_status
    FROM customer_demographics
),
combined_data AS (
    SELECT
        a.ca_city,
        a.ca_state,
        a.street_name_length,
        a.full_address,
        d.gender_description,
        d.cd_marital_status,
        d.cd_education_status
    FROM address_info a
    JOIN demographic_info d ON d.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk LIMIT 1)
)
SELECT
    ca_state,
    COUNT(*) AS address_count,
    AVG(street_name_length) AS avg_street_name_length,
    STRING_AGG(DISTINCT full_address, ', ') AS all_addresses,
    MAX(gender_description) AS most_common_gender,
    MIN(cd_marital_status) AS marital_status
FROM combined_data
GROUP BY ca_state
ORDER BY address_count DESC
LIMIT 10;
