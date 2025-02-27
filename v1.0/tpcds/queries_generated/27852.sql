
WITH address_summary AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type || ', ' || ca_zip, '; ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city
), 
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(CONCAT(cd_marital_status, ' - ', cd_education_status), '; ') AS marital_education_info
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), 
date_summary AS (
    SELECT 
        d_year,
        COUNT(*) AS total_sales_days,
        STRING_AGG(d_day_name, ', ') AS day_names
    FROM 
        date_dim
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.total_addresses,
    a.full_address_list,
    d.d_year,
    d.total_sales_days,
    d.day_names,
    de.cd_gender,
    de.total_customers,
    de.avg_purchase_estimate,
    de.marital_education_info
FROM 
    address_summary a
JOIN 
    date_summary d ON a.total_addresses > 50
JOIN 
    demographics_summary de ON de.total_customers > 100
ORDER BY 
    a.ca_city, d.d_year, de.cd_gender;
