
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateAnalysis AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        STRING_AGG(d_day_name, ', ') AS days_in_year
    FROM 
        date_dim
    GROUP BY 
        d_year
),
FinalBenchmark AS (
    SELECT 
        a.ca_city,
        a.address_count,
        a.street_names,
        d.d_year,
        d.total_dates,
        d.days_in_year,
        m.cd_gender,
        m.avg_purchase_estimate,
        m.max_dependents,
        m.marital_statuses
    FROM 
        AddressCounts a
    JOIN 
        DateAnalysis d ON a.address_count > 100 
    JOIN 
        DemographicStats m ON a.address_count < 200 
)
SELECT 
    *
FROM 
    FinalBenchmark
ORDER BY 
    address_count DESC, avg_purchase_estimate DESC;
