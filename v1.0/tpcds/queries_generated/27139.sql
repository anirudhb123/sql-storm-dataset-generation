
WITH Address AS (
    SELECT DISTINCT
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
),
Demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        INITCAP(cd_gender || ' | ' || cd_marital_status || ' | ' || cd_education_status) AS demographic_summary
    FROM customer_demographics
),
Aggregated AS (
    SELECT
        a.ca_city,
        a.ca_state,
        COUNT(DISTINCT a.ca_address_id) AS address_count,
        AVG(d.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(a.street_name_length) AS max_street_name_length
    FROM Address a
    JOIN customer c ON c.c_current_addr_sk = a.ca_address_sk
    JOIN Demographics d ON d.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY a.ca_city, a.ca_state
)
SELECT
    ca_city,
    ca_state,
    address_count,
    avg_purchase_estimate,
    max_street_name_length,
    CONCAT('In ', ca_city, ', ', ca_state, ' there are ', address_count, ' addresses with an average purchase estimate of ', ROUND(avg_purchase_estimate, 2), ' and the maximum street name length is ', max_street_name_length, '.') AS report
FROM Aggregated
ORDER BY ca_city, ca_state;
