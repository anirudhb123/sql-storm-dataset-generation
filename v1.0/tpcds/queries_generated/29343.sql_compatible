
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS full_address,
        REPLACE(LOWER(ca_city), ' ', '_') AS city_slug,
        CONCAT(ca_state, '_', ca_zip) AS state_zip
    FROM
        customer_address
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        DENSE_RANK() OVER (ORDER BY cd_purchase_estimate DESC) AS purchase_rank,
        cd_gender
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    pa.full_address,
    ci.full_name,
    ci.purchase_rank,
    COUNT(DISTINCT ci.c_customer_sk) OVER (PARTITION BY ci.purchase_rank) AS customer_count,
    pa.city_slug,
    pa.state_zip
FROM
    processed_addresses pa
JOIN
    customer_info ci ON pa.ca_address_sk = ci.c_customer_sk
WHERE
    ci.purchase_rank <= 10
ORDER BY
    ci.purchase_rank, pa.full_address;
