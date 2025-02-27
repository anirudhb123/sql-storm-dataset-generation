
WITH customer_data AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        DATEDIFF(CURRENT_DATE, CONCAT(c.c_birth_year, '-', c.c_birth_month, '-', c.c_birth_day)) / 365 AS age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
emails AS (
    SELECT 
        full_name,
        c_email_address,
        age,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_data
    WHERE 
        c_email_address IS NOT NULL AND
        UPPER(cd_gender) IN ('F', 'M')
),
top_10_emails AS (
    SELECT 
        full_name,
        c_email_address,
        age,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY age DESC) AS rn
    FROM 
        emails
)
SELECT 
    full_name,
    c_email_address,
    age,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    top_10_emails
WHERE 
    rn <= 10
ORDER BY 
    cd_gender, age DESC;
