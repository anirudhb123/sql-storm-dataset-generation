
WITH AddressData AS (
    SELECT 
        ca_address_id,
        UPPER(ca_city) AS upper_city,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REGEXP_REPLACE(ca_zip, '[^0-9]', '') AS cleaned_zip
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_birth_month = d.d_moy AND c.c_birth_day = d.d_dom
),
CombinedData AS (
    SELECT 
        a.ca_address_id,
        a.upper_city,
        a.street_name_length,
        a.full_address,
        a.cleaned_zip,
        c.full_name,
        c.birth_date,
        c.gender,
        c.marital_status,
        c.education_status
    FROM 
        AddressData a
    JOIN 
        CustomerData c ON a.ca_address_id = LEFT(c.c_customer_id, 16) 
)
SELECT 
    upper_city,
    COUNT(*) AS customer_count,
    AVG(street_name_length) AS avg_street_name_length,
    SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count,
    MIN(birth_date) AS earliest_birth_date,
    MAX(birth_date) AS latest_birth_date,
    LISTAGG(DISTINCT cleaned_zip, ', ') AS unique_zip_codes
FROM 
    CombinedData
GROUP BY 
    upper_city
ORDER BY 
    customer_count DESC, 
    upper_city;
