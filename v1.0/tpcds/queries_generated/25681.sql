
WITH Address_Stats AS (
    SELECT
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM
        customer_address
    GROUP BY
        ca_state
), 
Demographics_Stats AS (
    SELECT
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
Date_Stats AS (
    SELECT
        d_year,
        COUNT(*) AS total_dates,
        AVG(DATE_PART('day', d_date)) AS avg_days_in_month
    FROM
        date_dim
    GROUP BY
        d_year
), 
Combined_Stats AS (
    SELECT
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.max_street_name_length,
        a.min_street_name_length,
        d.cd_gender,
        d.total_customers,
        d.avg_dependents,
        d.max_purchase_estimate,
        d.min_purchase_estimate,
        dt.d_year,
        dt.total_dates,
        dt.avg_days_in_month
    FROM
        Address_Stats a
    JOIN 
        Demographics_Stats d ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = d.cd_demo_sk)
    JOIN 
        Date_Stats dt ON dt.d_year BETWEEN 2020 AND 2023
)
SELECT
    ca_state,
    SUM(total_addresses) AS total_addresses,
    AVG(avg_street_name_length) AS overall_avg_street_name_length,
    MAX(max_street_name_length) AS overall_max_street_name_length,
    MIN(min_street_name_length) AS overall_min_street_name_length,
    SUM(total_customers) AS total_customers,
    AVG(avg_dependents) AS overall_avg_dependents,
    MAX(max_purchase_estimate) AS overall_max_purchase_estimate,
    MIN(min_purchase_estimate) AS overall_min_purchase_estimate,
    SUM(total_dates) AS total_dates,
    AVG(avg_days_in_month) AS overall_avg_days_in_month
FROM
    Combined_Stats
GROUP BY
    ca_state
ORDER BY
    total_addresses DESC
LIMIT 10;
