
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_street_name, ', ') AS unique_street_names
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents,
        MIN(cd_dep_count) AS min_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateMetrics AS (
    SELECT 
        d_year,
        COUNT(*) AS total_days,
        LISTAGG(d_day_name, ', ') AS day_names
    FROM 
        date_dim
    WHERE 
        d_year BETWEEN 2019 AND 2022
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.address_count,
    a.unique_street_names,
    d.cd_gender,
    d.avg_purchase_estimate,
    d.max_dependents,
    d.min_dependents,
    date.d_year,
    date.total_days,
    date.day_names
FROM 
    AddressCounts a
JOIN 
    DemographicStats d ON TRUE
JOIN 
    DateMetrics date ON TRUE
ORDER BY 
    a.ca_city, d.cd_gender, date.d_year;
