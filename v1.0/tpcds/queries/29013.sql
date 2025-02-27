WITH AddressStats AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count, 
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS unique_addresses,
        MAX(ca_location_type) AS max_location_type,
        MIN(ca_gmt_offset) AS min_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
DateRangeStats AS (
    SELECT 
        d_year, 
        COUNT(DISTINCT d_date) AS total_days,
        STRING_AGG(DISTINCT d_day_name, ', ') FILTER (WHERE d_holiday = 'Y') AS holidays
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    A.ca_city, 
    A.ca_state, 
    A.address_count, 
    A.unique_addresses, 
    D.cd_gender, 
    D.cd_marital_status, 
    D.total_dependents, 
    D.employed_dependents,
    D.education_levels,
    R.d_year, 
    R.total_days, 
    R.holidays
FROM 
    AddressStats A
JOIN 
    DemographicsStats D ON A.ca_state = 'CA' 
JOIN 
    DateRangeStats R ON R.d_year = 2001 
ORDER BY 
    A.ca_city, 
    D.cd_gender;