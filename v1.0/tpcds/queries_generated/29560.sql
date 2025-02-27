
WITH string_benchmarks AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(REPLACE(c.c_email_address, '@', '[at]')) AS obfuscated_email,
        CASE
            WHEN c.c_birth_month IN (1, 2, 12) THEN 'Winter'
            WHEN c.c_birth_month IN (3, 4, 5) THEN 'Spring'
            WHEN c.c_birth_month IN (6, 7, 8) THEN 'Summer'
            ELSE 'Autumn'
        END AS birth_season,
        LENGTH(c.c_email_address) AS email_length,
        REGEXP_REPLACE(c.c_first_name, '[aeiou]', '*') AS vowel_replaced_first_name
    FROM
        customer c
),
demographic_info AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sb.full_name,
        sb.obfuscated_email,
        sb.birth_season,
        sb.email_length,
        sb.vowel_replaced_first_name
    FROM
        customer_demographics cd
    JOIN string_benchmarks sb ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT
    di.cd_gender,
    di.cd_marital_status,
    COUNT(*) AS count_customers,
    AVG(di.email_length) AS avg_email_length,
    STRING_AGG(DISTINCT di.birth_season) AS unique_birth_seasons,
    MAX(LENGTH(di.vowel_replaced_first_name)) AS max_modified_first_name_length
FROM
    demographic_info di
GROUP BY
    di.cd_gender,
    di.cd_marital_status
ORDER BY
    count_customers DESC;
