
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS order_count,
        AVG(d_dow) AS avg_day_of_week,
        STRING_AGG(DISTINCT d_day_name, ', ') AS unique_days
    FROM 
        date_dim
    WHERE 
        d_year >= 2020
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.min_zip,
    a.max_zip,
    a.unique_cities,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.marital_statuses,
    d.d_year,
    d.order_count,
    d.avg_day_of_week,
    d.unique_days
FROM 
    AddressStats a
CROSS JOIN 
    CustomerStats c
CROSS JOIN 
    DateStats d
ORDER BY 
    a.ca_state, c.cd_gender, d.d_year;
