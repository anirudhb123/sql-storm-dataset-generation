
WITH AddressCounts AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names
    FROM
        customer_address
    GROUP BY
        ca_state
),
DemographicsCounts AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
FinalBenchmark AS (
    SELECT
        a.ca_state,
        a.address_count,
        a.cities,
        a.street_names,
        d.cd_gender,
        d.demographic_count,
        d.avg_purchase_estimate,
        d.education_levels
    FROM
        AddressCounts a
    JOIN
        DemographicsCounts d ON a.address_count > d.demographic_count
)
SELECT
    f.ca_state,
    f.address_count,
    f.cities,
    f.street_names,
    f.cd_gender,
    f.demographic_count,
    ROUND(f.avg_purchase_estimate, 2) AS avg_purchase_estimate,
    f.education_levels
FROM
    FinalBenchmark f
ORDER BY
    f.address_count DESC, f.demographic_count DESC;
