
WITH address_data AS (
    SELECT
        ca_state,
        ca_city,
        COUNT(*) AS total_addresses,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        STRING_AGG(DISTINCT ca_street_name, '; ') AS street_names
    FROM
        customer_address
    GROUP BY
        ca_state, ca_city
),
demo_data AS (
    SELECT
        cd_marital_status,
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM
        customer_demographics
    GROUP BY
        cd_marital_status, cd_gender
)
SELECT
    a.ca_state,
    a.ca_city,
    a.total_addresses,
    a.max_zip,
    a.min_zip,
    a.avg_gmt_offset,
    a.street_names,
    d.cd_marital_status,
    d.cd_gender,
    d.total_demographics,
    d.avg_purchase_estimate,
    d.education_statuses
FROM
    address_data a
JOIN
    demo_data d ON a.ca_city LIKE '%' || d.cd_marital_status || '%'
ORDER BY
    a.ca_state, a.ca_city, d.cd_marital_status;
