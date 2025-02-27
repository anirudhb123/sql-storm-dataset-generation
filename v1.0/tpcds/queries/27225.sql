
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number, ', ') AS street_info
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        COUNT(cd_demo_sk) AS demo_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(d_date_sk) AS valid_dates,
        STRING_AGG(DISTINCT d_day_name, ', ') AS days_of_week
    FROM 
        date_dim
    WHERE 
        d_date >= '2022-01-01'
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.address_count,
    a.street_info,
    d.cd_gender,
    d.demo_count,
    d.avg_purchase_estimate,
    d.education_levels,
    ds.d_year,
    ds.valid_dates,
    ds.days_of_week
FROM 
    AddressStats a
JOIN 
    DemographicsStats d ON a.address_count > 10
JOIN 
    DateStats ds ON d.demo_count > 20 
ORDER BY 
    a.ca_city, d.cd_gender;
