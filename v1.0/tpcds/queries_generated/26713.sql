
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        SUBSTRING(ca_city FROM 1 FOR 3) AS city_prefix,
        ca_state,
        ca_zip
    FROM
        customer_address
),
GenderDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM
        customer_demographics
    GROUP BY
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.city_prefix,
        a.ca_state,
        a.ca_zip,
        g.cd_gender,
        g.cd_marital_status,
        g.max_purchase_estimate
    FROM
        customer c
    JOIN
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN
        GenderDemographics g ON c.c_current_cdemo_sk = g.cd_demo_sk
)
SELECT
    city_prefix,
    ca_state,
    COUNT(*) AS customer_count,
    AVG(max_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
FROM
    CustomerDetails
WHERE
    ca_zip LIKE '1234%' AND cd_gender = 'F'
GROUP BY
    city_prefix, ca_state
ORDER BY
    city_prefix, ca_state;
