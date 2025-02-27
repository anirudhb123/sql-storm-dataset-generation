
WITH AddressInfo AS (
    SELECT
        ca_address_id,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_state) AS state_lower
    FROM
        customer_address
), DemoInfo AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital_status,
        cd_purchase_estimate,
        COALESCE(cd_credit_rating, 'N/A') AS credit_rating
    FROM
        customer_demographics
), CombinedInfo AS (
    SELECT
        a.ca_address_id,
        a.full_address,
        a.city_upper,
        a.state_lower,
        d.cd_gender,
        d.cd_marital_status,
        d.gender_marital_status,
        d.cd_purchase_estimate,
        d.credit_rating
    FROM
        AddressInfo a
    JOIN
        DemoInfo d ON a.ca_address_id LIKE CONCAT('%', d.cd_demo_sk, '%')
)
SELECT
    REGEXP_REPLACE(full_address, '[^A-Za-z0-9 ]', '') AS sanitized_address,
    LENGTH(full_address) AS address_length,
    city_upper,
    state_lower,
    COUNT(*) OVER (PARTITION BY cd_gender) AS gender_count,
    SUM(cd_purchase_estimate) OVER (PARTITION BY cd_marital_status) AS total_estimate_marital,
    MAX(LENGTH(gender_marital_status)) AS max_gender_marital_length
FROM
    CombinedInfo
ORDER BY
    address_length DESC
LIMIT 100;
