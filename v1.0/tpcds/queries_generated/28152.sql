
WITH processed_addresses AS (
    SELECT 
        ca_city AS city,
        ca_state AS state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_country AS country,
        LENGTH(ca_zip) AS zip_length
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
processed_demographics AS (
    SELECT 
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education,
        LPAD(cd_purchase_estimate, 6, '0') AS purchase_estimate_formatted,
        cd_credit_rating AS credit_rating
    FROM 
        customer_demographics
),
demographics_with_address AS (
    SELECT 
        d.city, 
        d.state, 
        d.full_address, 
        d.country, 
        dem.gender, 
        dem.marital_status, 
        dem.education, 
        dem.purchase_estimate_formatted, 
        dem.credit_rating
    FROM 
        processed_addresses d
    JOIN 
        processed_demographics dem ON d.country = 'USA'
)
SELECT 
    state,
    COUNT(DISTINCT full_address) AS unique_addresses,
    MAX(zip_length) AS max_zip_length,
    COUNT(DISTINCT gender) AS distinct_genders,
    COUNT(DISTINCT marital_status) AS distinct_marital_statuses,
    AVG(LENGTH(purchase_estimate_formatted)) AS avg_purchase_estimate_length
FROM 
    demographics_with_address
GROUP BY 
    state
ORDER BY 
    state ASC;
