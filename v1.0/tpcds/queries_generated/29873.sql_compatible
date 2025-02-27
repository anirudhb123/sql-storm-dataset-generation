
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        COUNT(ca_city) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsSummary AS (
    SELECT
        cd_gender,
        COUNT(cd_demo_sk) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateSummary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS distinct_days,
        COUNT(d_date) AS total_days,
        STRING_AGG(d_day_name, ', ') AS week_days
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.address_count,
    a.max_street_name_length,
    a.min_street_name_length,
    d.cd_gender,
    d.demo_count,
    d.avg_purchase_estimate,
    d.marital_statuses,
    dt.d_year,
    dt.distinct_days,
    dt.total_days,
    dt.week_days
FROM 
    AddressSummary a
JOIN 
    DemographicsSummary d ON a.unique_addresses > 100
JOIN 
    DateSummary dt ON dt.distinct_days > 30
ORDER BY 
    a.ca_state, d.cd_gender, dt.d_year;
