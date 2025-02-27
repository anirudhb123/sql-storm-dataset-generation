
WITH AddressAnalysis AS (
    SELECT 
        ca_address_sk,
        UPPER(ca_city) AS city_uppercase,
        LOWER(ca_street_name) AS street_lowercase,
        TRIM(ca_street_number) AS street_number_trimmed,
        CONCAT(ca_street_type, ' ', ca_street_name) AS full_street_name,
        LENGTH(ca_zip) AS zip_length
    FROM 
        customer_address
),
DemographicsAnalysis AS (
    SELECT 
        cd_demo_sk,
        REPLACE(cd_gender, 'M', 'Male') AS gender_full,
        REPLACE(cd_gender, 'F', 'Female') AS gender_full,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status_full,
        INITCAP(cd_education_status) AS education_capitalized
    FROM 
        customer_demographics
),
CombinedAnalysis AS (
    SELECT 
        a.ca_address_sk,
        a.city_uppercase,
        a.street_lowercase,
        d.cd_demo_sk,
        d.gender_full,
        d.marital_status_full,
        d.education_capitalized,
        ROW_NUMBER() OVER (PARTITION BY a.ca_address_sk ORDER BY d.cd_demo_sk) AS row_num
    FROM 
        AddressAnalysis a
    JOIN 
        DemographicsAnalysis d ON d.cd_demo_sk = a.ca_address_sk % (SELECT COUNT(*) FROM customer_demographics)
)
SELECT 
    ca_address_sk,
    city_uppercase,
    street_lowercase,
    gender_full,
    marital_status_full,
    education_capitalized
FROM 
    CombinedAnalysis
WHERE 
    row_num <= 5
ORDER BY 
    ca_address_sk;
