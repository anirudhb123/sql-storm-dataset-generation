
WITH AddressDetails AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        STRING_AGG(CONCAT(cd_gender, ' ', cd_marital_status), ', ') AS demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateDetails AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        STRING_AGG(DISTINCT d_day_name, ', ') AS days
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.full_addresses,
    C.cd_gender,
    C.cd_marital_status,
    C.total_dependents,
    C.demographics,
    D.d_year,
    D.total_dates,
    D.days
FROM 
    AddressDetails A
JOIN 
    CustomerDetails C ON 1=1
JOIN 
    DateDetails D ON 1=1
ORDER BY 
    A.ca_state, C.cd_gender, D.d_year;
