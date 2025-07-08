
WITH AddressAnalysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        LISTAGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names,
        SUM(CASE WHEN ca_country = 'USA' THEN 1 ELSE 0 END) AS usa_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicsAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count,
        LISTAGG(DISTINCT cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_list,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateAnalysis AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        MAX(d_date) AS latest_date,
        MIN(d_date) AS earliest_date
    FROM 
        date_dim
    GROUP BY 
        d_year
),
WarehouseAnalysis AS (
    SELECT 
        w_state,
        SUM(w_warehouse_sq_ft) AS total_sq_ft,
        COUNT(*) AS warehouse_count
    FROM 
        warehouse
    GROUP BY 
        w_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.street_names,
    a.usa_addresses,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    d.education_list,
    d.avg_purchase_estimate,
    da.d_year,
    da.total_dates,
    da.latest_date,
    da.earliest_date,
    w.warehouse_count,
    w.total_sq_ft
FROM 
    AddressAnalysis a
JOIN 
    DemographicsAnalysis d ON a.ca_state = d.cd_marital_status  
JOIN 
    DateAnalysis da ON a.unique_addresses % 100 = da.total_dates % 100  
JOIN 
    WarehouseAnalysis w ON a.ca_state = w.w_state
ORDER BY 
    a.ca_city, 
    d.cd_gender;
