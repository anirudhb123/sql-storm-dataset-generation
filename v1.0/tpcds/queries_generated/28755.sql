
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, ''), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
), 
customer_details AS (
    SELECT 
        c_customer_sk,
        TRIM(CONCAT(c_first_name, ' ', c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_birth_month,
        cd_birth_year,
        ca_city,
        ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    pd.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(EXTRACT(YEAR FROM CURRENT_DATE) - cd.cd_birth_year) AS average_age
FROM processed_addresses pd
JOIN customer_details cd ON pd.ca_city = cd.ca_city AND pd.ca_state = cd.ca_state
WHERE pd.ca_zip LIKE '9%' -- Only addresses with zip codes starting with '9'
GROUP BY pd.full_address, cd.full_name, cd.cd_gender, cd.cd_marital_status
HAVING COUNT(*) > 1
ORDER BY average_age DESC, customer_count DESC;
