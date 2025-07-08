
WITH Address_Analysis AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_street_name) AS street_lower,
        LENGTH(ca_zip) AS zip_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(SUBSTRING(ca_street_name, 1, 30)) AS truncated_street_name
    FROM 
        customer_address
), Demographic_Analysis AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_description,
        cd_marital_status,
        COUNT(*) OVER (PARTITION BY cd_gender) AS gender_count,
        (SELECT COUNT(*) FROM customer) AS total_customers
    FROM 
        customer_demographics
), Combined_Analysis AS (
    SELECT 
        a.ca_address_sk,
        a.city_upper,
        a.street_lower,
        a.zip_length,
        a.full_address,
        a.truncated_street_name,
        d.gender_description,
        d.cd_marital_status AS marital_status,
        d.gender_count,
        d.total_customers
    FROM 
        Address_Analysis a
    JOIN 
        Demographic_Analysis d ON a.ca_address_sk % 100 = d.cd_demo_sk % 100
)

SELECT 
    city_upper,
    COUNT(*) AS address_count,
    AVG(zip_length) AS avg_zip_length,
    LISTAGG(DISTINCT gender_description, ', ') AS gender_distribution,
    SUM(gender_count) AS total_gender_count
FROM 
    Combined_Analysis
GROUP BY 
    ca_address_sk, city_upper, street_lower, zip_length, full_address, truncated_street_name, gender_description, marital_status, gender_count, total_customers
ORDER BY 
    address_count DESC;
