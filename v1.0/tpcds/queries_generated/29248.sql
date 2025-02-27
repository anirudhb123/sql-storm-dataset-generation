
WITH enriched_customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_address_id,
        CONCAT(TRIM(ca.ca_street_number), ' ', TRIM(ca.ca_street_name), ' ', TRIM(ca.ca_street_type), 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca.ca_suite_number)) ELSE '' END
        ) AS full_address,
        CONCAT(TRIM(ca.ca_city), ', ', TRIM(ca.ca_state), ' ', TRIM(ca.ca_zip)) AS city_state_zip,
        ca.ca_country
    FROM customer_address AS ca
),
address_stats AS (
    SELECT 
        ca.ca_address_sk,
        LENGTH(full_address) AS address_length,
        REGEXP_COUNT(full_address, '[A-Za-z]+') AS word_count,
        UPPER(full_address) AS upper_case_address,
        LOWER(full_address) AS lower_case_address,
        SUBSTR(full_address, 1, 10) AS address_prefix
    FROM enriched_customer_addresses AS ca
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        a.city_state_zip,
        a.address_length,
        a.word_count
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN address_stats AS a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ci.city_state_zip,
    ci.address_length,
    ci.word_count
FROM customer_info AS ci
LEFT JOIN income_band AS ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
WHERE ci.word_count > 3
ORDER BY ci.city_state_zip, ci.c_last_name, ci.c_first_name;
