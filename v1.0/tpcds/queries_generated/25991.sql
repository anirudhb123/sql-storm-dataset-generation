
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper,
        REPLACE(ca_zip, '-', '') AS zip_cleaned
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
),
DateInfo AS (
    SELECT 
        EXTRACT(YEAR FROM d_date) AS year, 
        d_day_name,
        COUNT(DISTINCT d_date_id) AS unique_dates
    FROM 
        date_dim
    GROUP BY 
        year, 
        d_day_name
)
SELECT 
    pa.full_address, 
    pa.city_lower, 
    pa.state_upper, 
    pa.zip_cleaned, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    di.year, 
    di.d_day_name, 
    di.unique_dates
FROM 
    ProcessedAddresses pa
JOIN 
    CustomerDemographics cd ON pa.ca_address_sk = cd.cd_demo_sk
JOIN 
    DateInfo di ON EXTRACT(YEAR FROM CURRENT_DATE) = di.year
WHERE 
    cd.demographic_count > 1
ORDER BY 
    pa.city_lower, 
    di.unique_dates DESC
LIMIT 100;
