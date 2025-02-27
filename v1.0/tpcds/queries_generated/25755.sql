
WITH AddressStats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
DemoStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
DateStats AS (
    SELECT
        d_year,
        COUNT(*) AS total_dates,
        COUNT(DISTINCT d_day_name) AS distinct_days,
        AVG(DATEDIFF(d_date, '2000-01-01')) AS avg_days_from_base_date
    FROM
        date_dim
    GROUP BY
        d_year
)
SELECT
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.max_purchase_estimate,
    d.min_purchase_estimate,
    da.d_year,
    da.total_dates,
    da.distinct_days,
    da.avg_days_from_base_date
FROM
    AddressStats a
JOIN
    DemoStats d ON a.address_count > 10
JOIN
    DateStats da ON da.total_dates > 2000
ORDER BY
    a.address_count DESC,
    d.demographic_count DESC,
    da.d_year ASC
LIMIT 100;
