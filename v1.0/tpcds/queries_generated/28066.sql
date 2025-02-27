
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    GROUP BY ca_state
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_demographics,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS unique_education_statuses
    FROM customer_demographics
    GROUP BY cd_gender
),
DateStats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        STRING_AGG(DISTINCT d_day_name, ', ') AS unique_days,
        COUNT(DISTINCT d_month_seq) AS total_months
    FROM date_dim
    GROUP BY d_year
),
WarehouseStats AS (
    SELECT 
        w_state,
        AVG(w_warehouse_sq_ft) AS avg_warehouse_sq_ft,
        COUNT(*) AS total_warehouses
    FROM warehouse
    GROUP BY w_state
)
SELECT 
    a.ca_state, 
    a.total_addresses, 
    a.unique_cities, 
    a.avg_gmt_offset, 
    g.cd_gender, 
    g.total_demographics, 
    g.avg_purchase_estimate, 
    g.unique_education_statuses, 
    d.d_year, 
    d.total_dates, 
    d.unique_days, 
    d.total_months, 
    w.w_state, 
    w.avg_warehouse_sq_ft, 
    w.total_warehouses
FROM AddressStats a
JOIN GenderStats g ON a.total_addresses > 100
JOIN DateStats d ON d.total_dates > 365
JOIN WarehouseStats w ON w.total_warehouses > 50
ORDER BY a.ca_state, g.cd_gender, d.d_year;
