
WITH processed_addresses AS (
    SELECT ca_address_sk,
           TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) AS full_address,
           ca_city,
           ca_state,
           ca_zip
    FROM customer_address
),
address_counts AS (
    SELECT ca_city,
           ca_state,
           COUNT(*) AS address_count,
           LISTAGG(full_address, '; ') WITHIN GROUP (ORDER BY full_address) AS address_list
    FROM processed_addresses
    GROUP BY ca_city, ca_state
),
demographics AS (
    SELECT cd_gender,
           cd_marital_status,
           COUNT(DISTINCT c_customer_sk) AS customer_count,
           SUM(cd_dep_count) AS total_dependencies
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_gender, cd_marital_status
)
SELECT d.ca_city,
       d.ca_state,
       d.address_count,
       d.address_list,
       dem.customer_count,
       dem.total_dependencies
FROM address_counts d
JOIN demographics dem ON dem.customer_count > 0
ORDER BY d.address_count DESC, d.ca_city, d.ca_state;
