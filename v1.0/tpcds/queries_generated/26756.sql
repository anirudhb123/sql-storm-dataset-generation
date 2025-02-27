
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(cd_education_status || ' (' || cd_marital_status || ')', ', ') AS education_marital_details
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateInfo AS (
    SELECT 
        d_year,
        COUNT(d_date_id) AS total_dates,
        STRING_AGG(d_day_name, ', ') AS days_in_year
    FROM 
        date_dim
    GROUP BY 
        d_year
),
WarehouseDetails AS (
    SELECT 
        w_city, 
        AVG(w_warehouse_sq_ft) AS avg_sq_ft,
        STRING_AGG(w_warehouse_name, ', ') AS warehouse_names
    FROM 
        warehouse
    GROUP BY 
        w_city
)
SELECT 
    a.ca_city,
    a.total_addresses,
    a.street_names,
    d.cd_gender,
    d.demographic_count,
    d.education_marital_details,
    dt.d_year,
    dt.total_dates,
    dt.days_in_year,
    w.w_city,
    w.avg_sq_ft,
    w.warehouse_names
FROM 
    AddressCounts a
JOIN 
    DemographicCounts d ON a.total_addresses > 100
JOIN 
    DateInfo dt ON dt.total_dates > 365
JOIN 
    WarehouseDetails w ON a.ca_city = w.w_city
ORDER BY 
    a.total_addresses DESC, d.demographic_count DESC;
