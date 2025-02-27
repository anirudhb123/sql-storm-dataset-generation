
WITH StringMetrics AS (
    SELECT
        ca_address_sk,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_name) AS lower_street_name,
        LENGTH(ca_street_name) AS street_name_length,
        TRIM(ca_street_name) AS trimmed_street_name,
        REPLACE(ca_street_name, ' ', '-') AS dash_replaced_street_name,
        CONCAT(ca_street_number, ' ', ca_street_name) AS full_address
    FROM
        customer_address
),
DemographicStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status) AS marital_statuses
    FROM
        customer_demographics
    GROUP BY
        cd_gender
)
SELECT
    sm.sm_carrier,
    STRING_AGG(DISTINCT CONCAT(dm.upper_street_name, ' (', dm.street_name_length, ')')) AS unique_address_names,
    ds.count AS demographic_count,
    ds.avg_purchase_estimate,
    ds.marital_statuses
FROM
    StringMetrics dm
JOIN
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT MIN(sm2.sm_ship_mode_sk) FROM ship_mode sm2)
JOIN
    DemographicStats ds ON ds.count > 100
GROUP BY
    sm.sm_carrier, ds.count, ds.avg_purchase_estimate
ORDER BY
    ds.avg_purchase_estimate DESC, sm.sm_carrier;
