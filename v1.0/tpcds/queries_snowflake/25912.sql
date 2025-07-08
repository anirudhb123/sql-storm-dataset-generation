
WITH Address_Analysis AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        CONCAT(ca_city, ', ', ca_state) AS full_address,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        LISTAGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM
        customer_address
    GROUP BY
        ca_city,
        ca_state
),
Demographics_Analysis AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(cd_demo_sk) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM
        customer_demographics
    GROUP BY
        cd_gender,
        cd_marital_status
)
SELECT
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.full_address,
    a.max_zip,
    a.min_zip,
    a.max_street_name_length,
    a.avg_street_name_length,
    a.street_types,
    d.cd_gender,
    d.cd_marital_status,
    d.demo_count,
    d.avg_purchase_estimate,
    d.education_levels
FROM
    Address_Analysis a
JOIN
    Demographics_Analysis d ON a.address_count > d.demo_count
ORDER BY
    a.address_count DESC,
    d.demo_count DESC
LIMIT 100;
