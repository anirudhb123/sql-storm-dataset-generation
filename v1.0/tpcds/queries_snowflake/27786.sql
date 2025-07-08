
WITH address_summary AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(ca_address_sk) AS total_addresses,
        LISTAGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(cd_demo_sk) AS total_demographics,
        LISTAGG(cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_list
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
date_summary AS (
    SELECT 
        d_year, 
        COUNT(d_date_sk) AS total_dates,
        LISTAGG(d_day_name, ', ') WITHIN GROUP (ORDER BY d_day_name) AS day_names_list
    FROM 
        date_dim
    GROUP BY 
        d_year
)

SELECT 
    a.ca_city, 
    a.ca_state, 
    a.total_addresses, 
    a.full_address_list, 
    d.cd_gender, 
    d.cd_marital_status, 
    d.total_demographics, 
    d.education_list, 
    dt.d_year, 
    dt.total_dates, 
    dt.day_names_list
FROM 
    address_summary a
JOIN 
    demographics_summary d ON a.total_addresses > 10
JOIN 
    date_summary dt ON dt.total_dates > 1000
WHERE 
    a.ca_state IN ('CA', 'TX')
ORDER BY 
    a.total_addresses DESC, d.total_demographics DESC, dt.total_dates DESC;
