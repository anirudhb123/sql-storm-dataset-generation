
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(COALESCE(LENGTH(ca_street_name), 0)) AS avg_street_name_length,
        MAX(COALESCE(LENGTH(ca_zip), 0)) AS max_zip_length,
        MIN(COALESCE(LENGTH(ca_street_number), 0)) AS min_street_number_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimation
    FROM customer_demographics
    GROUP BY cd_gender
),
AverageIncome AS (
    SELECT 
        ib_income_band_sk,
        (ib_lower_bound + ib_upper_bound) / 2 AS avg_income
    FROM income_band
)
SELECT 
    as.ca_state,
    as.total_addresses,
    as.avg_street_name_length,
    as.max_zip_length,
    as.min_street_number_length,
    cs.cd_gender,
    cs.total_customers,
    cs.avg_dependent_count,
    cs.max_purchase_estimation,
    ai.avg_income
FROM AddressStats as
JOIN CustomerStats cs ON as.total_addresses > 100
JOIN AverageIncome ai ON cs.total_customers > 50
ORDER BY as.total_addresses DESC, cs.total_customers DESC;
