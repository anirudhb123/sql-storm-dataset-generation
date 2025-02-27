
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_country) AS country_lower
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital,
        (cd_dep_count + cd_dep_employed_count + cd_dep_college_count) AS total_dependents
    FROM 
        customer_demographics
),
DateDetails AS (
    SELECT 
        d_date,
        d_month_seq,
        d_year,
        d_day_name,
        CASE 
            WHEN d_current_day = 'Y' THEN 'Today'
            ELSE d_day_name 
        END AS day_desc
    FROM 
        date_dim
),
CombinedDetails AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        dd.gender_marital,
        dd.total_dependents,
        dt.day_desc,
        dt.d_year
    FROM 
        AddressDetails ad
    JOIN 
        DemographicDetails dd ON dd.cd_purchase_estimate > 1000
    JOIN 
        DateDetails dt ON dt.d_year = 2023
)

SELECT 
    CONCAT('Address: ', full_address, ', ', ca_city, ', ', ca_state, ' - ', ca_zip, ' | Country: ', ca_country) AS formatted_address,
    gender_marital,
    total_dependents,
    day_desc
FROM 
    CombinedDetails
ORDER BY 
    ca_city, ca_state;
