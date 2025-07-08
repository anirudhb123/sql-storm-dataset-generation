
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        ca_street_number,
        TRIM(ca_street_name) AS street_name_trimmed,
        TRIM(ca_street_type) AS street_type_trimmed,
        ca_city,
        ca_state,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), ', ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)) AS full_address
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        a.full_address
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
StringProcessed AS (
    SELECT
        c.c_customer_sk,
        c.full_name,
        c.cd_gender,
        REPLACE(c.cd_marital_status, 'S', 'Single') AS marital_status,
        LENGTH(c.full_name) AS name_length,
        UPPER(c.full_name) AS name_upper,
        LOWER(c.full_name) AS name_lower,
        c.full_address
    FROM
        CustomerInfo c
)
SELECT
    cd_gender,
    COUNT(*) AS customer_count,
    AVG(name_length) AS average_name_length,
    LISTAGG(DISTINCT name_upper, ', ') AS unique_uppercase_names
FROM
    StringProcessed
GROUP BY
    cd_gender
ORDER BY
    customer_count DESC;
