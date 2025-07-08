
WITH address_stats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        LISTAGG(DISTINCT ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_type) AS unique_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
demographics_stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        LISTAGG(DISTINCT cd_education_status, '; ') WITHIN GROUP (ORDER BY cd_education_status) AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_stats AS (
    SELECT 
        d_year, 
        COUNT(DISTINCT d_date_id) AS total_days,
        MAX(d_dom) AS max_day_of_month,
        MIN(d_dom) AS min_day_of_month,
        LISTAGG(DISTINCT d_day_name, ', ') WITHIN GROUP (ORDER BY d_day_name) AS days_of_week
    FROM 
        date_dim
    GROUP BY 
        d_year
),
summary AS (
    SELECT 
        a.ca_city,
        a.ca_state,
        a.total_addresses,
        a.avg_street_name_length,
        a.unique_street_types,
        d.total_days AS total_days_in_year,
        d.max_day_of_month,
        d.min_day_of_month,
        d.days_of_week,
        dem.total_customers,
        dem.avg_dependents,
        dem.education_levels
    FROM 
        address_stats a
    JOIN 
        date_stats d ON a.ca_state = 'CA'
    JOIN 
        demographics_stats dem ON dem.cd_gender = 'M'
)
SELECT 
    * 
FROM 
    summary
WHERE 
    total_addresses > 100
ORDER BY 
    total_customers DESC, total_addresses DESC;
