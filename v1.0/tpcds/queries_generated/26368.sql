
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(ca_city) AS city_lower,
        CONCAT(ca_state, '-', ca_zip) AS state_zip
    FROM
        customer_address
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ca.full_address,
    ca.city_lower,
    ca.state_zip,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd.cd_credit_rating) AS unique_credit_ratings
FROM
    processed_addresses AS ca
LEFT JOIN
    customer_details AS cd ON cd.c_customer_sk IN (
        SELECT
            c.c_customer_sk
        FROM
            customer AS c
        WHERE
            c.c_current_addr_sk = ca.ca_address_sk
    )
GROUP BY
    ca.full_address,
    ca.city_lower,
    ca.state_zip
ORDER BY
    customer_count DESC,
    avg_purchase_estimate DESC
LIMIT 100;
