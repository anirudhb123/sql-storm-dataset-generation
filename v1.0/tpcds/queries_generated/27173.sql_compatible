
WITH CustomerDetails AS (
    SELECT c.c_customer_id,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           ca.ca_city,
           ca.ca_state,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           CONCAT(cd.cd_education_status, ' (', cd.cd_credit_rating, ')') AS education_credit
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StringAnalysis AS (
    SELECT full_name,
           LENGTH(full_name) AS name_length,
           CHAR_LENGTH(full_name) AS name_char_length,
           TRIM(full_name) AS trimmed_name,
           UPPER(full_name) AS upper_name,
           LOWER(full_name) AS lower_name,
           REPLACE(full_name, ' ', '-') AS hyphenated_name,
           REGEXP_REPLACE(full_name, '[^A-Za-z]', '') AS alphabets_only
    FROM CustomerDetails
),
AggregatedData AS (
    SELECT ca_city,
           ca_state,
           COUNT(*) AS customer_count,
           AVG(name_length) AS avg_name_length,
           MAX(name_length) AS max_name_length,
           MIN(name_length) AS min_name_length
    FROM StringAnalysis
    GROUP BY ca_city, ca_state
)
SELECT ad.ca_city,
       ad.ca_state,
       ad.customer_count,
       ad.avg_name_length,
       ad.max_name_length,
       ad.min_name_length,
       STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status), '; ') AS gender_marital_info
FROM AggregatedData ad
JOIN CustomerDetails cd ON ad.ca_city = cd.ca_city AND ad.ca_state = cd.ca_state
GROUP BY ad.ca_city, ad.ca_state, ad.customer_count, ad.avg_name_length, ad.max_name_length, ad.min_name_length
ORDER BY ad.ca_city, ad.ca_state;
