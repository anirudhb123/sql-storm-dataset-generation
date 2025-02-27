
WITH Address_Stats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics_Stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographics_count,
        STRING_AGG(CONCAT(cd_marital_status, ' ', cd_education_status), '; ') AS demographic_details
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
Date_Stats AS (
    SELECT 
        d_year,
        COUNT(*) AS total_dates,
        STRING_AGG(TO_CHAR(d_date, 'YYYY-MM-DD'), ', ') AS date_list
    FROM 
        date_dim
    GROUP BY 
        d_year
)

SELECT 
    a.ca_state,
    a.address_count,
    a.full_address_list,
    d.cd_gender,
    d.demographics_count,
    d.demographic_details,
    t.d_year,
    t.total_dates,
    t.date_list
FROM 
    Address_Stats a
JOIN 
    Demographics_Stats d ON a.address_count > d.demographics_count
JOIN 
    Date_Stats t ON d.demographics_count < t.total_dates
WHERE 
    LENGTH(a.full_address_list) > 100
ORDER BY 
    a.address_count DESC, d.demographics_count DESC, t.total_dates DESC
LIMIT 50;
