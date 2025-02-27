
WITH CustomerAddress AS (
    SELECT ca_address_sk, 
           TRIM(UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
           ca_city,
           ca_state,
           ca_zip,
           ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_email_address,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           REPLACE(LOWER(c.c_email_address), '@', ' [at] ') AS sanitized_email
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT ca.ca_address_sk,
           ca.full_address,
           ca.ca_city,
           ca.ca_state,
           ca.ca_zip,
           ca.ca_country,
           cd.full_name,
           cd.sanitized_email
    FROM CustomerAddress ca
    JOIN CustomerDetails cd ON cd.c_customer_sk = ca.ca_address_sk
),
AggregatedInfo AS (
    SELECT LENGTH(full_address) AS address_length,
           COUNT(*) AS address_count,
           MIN(ca_state) AS first_state,
           MAX(ca_state) AS last_state,
           STRING_AGG(full_name, ', ') AS customer_names
    FROM AddressInfo
    GROUP BY full_address
)
SELECT *,
       address_length * address_count AS benchmark_score
FROM AggregatedInfo
WHERE address_count > 1
ORDER BY benchmark_score DESC
LIMIT 100;
