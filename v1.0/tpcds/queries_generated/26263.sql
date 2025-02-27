
WITH CustomerAddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemoStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demo_count,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS date_count,
        STRING_AGG(DISTINCT d_day_name, ', ') AS unique_days
    FROM 
        date_dim 
    GROUP BY 
        d_year
)
SELECT 
    cs.ca_city, 
    cs.ca_state, 
    cs.address_count, 
    cs.unique_addresses, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.demo_count, 
    cd.unique_education_statuses, 
    ds.d_year, 
    ds.date_count, 
    ds.unique_days
FROM 
    CustomerAddressStats cs
JOIN 
    CustomerDemoStats cd ON cs.address_count > cd.demo_count
JOIN 
    DateStats ds ON ds.date_count > cs.address_count
ORDER BY 
    cs.ca_city, cs.ca_state, cd.cd_gender, ds.d_year;
