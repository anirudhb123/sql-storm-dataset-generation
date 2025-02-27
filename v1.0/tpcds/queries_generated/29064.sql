
WITH address_data AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_street_name) AS street_name_upper,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(ca_city) AS city_trimmed,
        TRIM(ca_state) AS state_trimmed,
        REPLACE(ca_zip, '-', '') AS zip_cleaned
    FROM customer_address
),
demographics_data AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_full,
        cd_marital_status AS marital_status,
        cd_education_status AS education
    FROM customer_demographics
),
dates_data AS (
    SELECT 
        d_date_sk,
        TO_CHAR(d_date, 'YYYY-MM-DD') AS formatted_date,
        EXTRACT(MONTH FROM d_date) AS month,
        EXTRACT(YEAR FROM d_date) AS year,
        CASE 
            WHEN d_weekend = 'Y' THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM date_dim
),
combined_data AS (
    SELECT 
        a.ca_address_sk,
        a.street_name_upper,
        a.street_name_length,
        a.full_address,
        a.city_trimmed,
        a.state_trimmed,
        a.zip_cleaned,
        d.gender_full,
        d.marital_status,
        d.education,
        da.formatted_date,
        da.month,
        da.year,
        da.day_type
    FROM address_data a
    JOIN demographics_data d ON a.ca_address_sk % 1000 = d.cd_demo_sk % 1000
    JOIN dates_data da ON a.ca_address_sk % 1000 = da.d_date_sk % 1000
)
SELECT 
    city_trimmed,
    COUNT(*) AS address_count,
    AVG(street_name_length) AS avg_street_length,
    STRING_AGG(full_address, ', ') AS all_addresses,
    STRING_AGG(DISTINCT gender_full) AS unique_genders
FROM combined_data
GROUP BY city_trimmed
HAVING COUNT(*) > 10
ORDER BY address_count DESC;
