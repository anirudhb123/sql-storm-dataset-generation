
WITH processed_addresses AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        REPLACE(UPPER(ca.ca_city), 'CITY', 'METRO') AS modified_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer_address ca
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.full_address,
        ca.modified_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    ci.full_name,
    ci.cd_gender,
    COUNT(CASE WHEN ci.cd_marital_status = 'M' THEN 1 END) AS married_count,
    COUNT(CASE WHEN ci.cd_marital_status = 'S' THEN 1 END) AS single_count,
    AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(ci.modified_city, ' - ', ci.ca_state, ' ', ci.ca_zip, ' ', ci.ca_country)) AS unique_addresses
FROM
    customer_info ci
GROUP BY
    ci.full_name, ci.cd_gender
ORDER BY
    ci.cd_gender, avg_purchase_estimate DESC
LIMIT 100;
