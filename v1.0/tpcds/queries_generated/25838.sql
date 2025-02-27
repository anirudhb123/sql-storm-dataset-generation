
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
DemographicsInfo AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status) AS gender_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        c_email_address,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        d_date AS registration_date
    FROM 
        customer
    JOIN 
        date_dim ON c_first_shipto_date_sk = d_date_sk
),
Integration AS (
    SELECT 
        A.full_address,
        A.ca_city,
        A.ca_state,
        A.ca_zip,
        D.gender_marital_status,
        D.cd_education_status,
        D.cd_purchase_estimate,
        C.full_name,
        C.c_email_address,
        C.c_birth_day,
        C.c_birth_month,
        C.c_birth_year,
        C.registration_date
    FROM 
        AddressInfo A
    JOIN 
        DemographicsInfo D ON D.cd_demo_sk = C.c_current_cdemo_sk
    JOIN 
        CustomerInfo C ON C.c_customer_sk = D.cd_demo_sk
)
SELECT 
    COUNT(*) AS total_customers,
    MAX(LENGTH(full_address)) AS max_address_length,
    MIN(LENGTH(full_address)) AS min_address_length,
    AVG(LENGTH(full_address)) AS avg_address_length,
    MAX(CASE WHEN ca_state = 'NY' THEN full_address END) AS ny_address_max_length,
    MIN(CASE WHEN ca_state = 'NY' THEN full_address END) AS ny_address_min_length
FROM 
    Integration;
