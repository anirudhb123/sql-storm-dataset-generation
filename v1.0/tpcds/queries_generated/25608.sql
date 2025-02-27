
WITH CustomerData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(c.ca_street_number, ' ', c.ca_street_name, ' ', c.ca_street_type, 
               CASE WHEN c.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', c.ca_suite_number) END, 
               ', ', c.ca_city, ', ', c.ca_state, ' ', c.ca_zip) AS full_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND
        cd.cd_gender = 'F' AND
        (c.c_birth_month = 1 OR c.c_birth_month = 6)
),
AggregatedData AS (
    SELECT 
        full_name,
        COUNT(*) OVER (PARTITION BY full_name) AS name_count,
        COUNT(DISTINCT c_email_address) OVER (PARTITION BY full_name) AS unique_emails,
        ROW_NUMBER() OVER (ORDER BY full_name) AS row_num
    FROM 
        CustomerData
)
SELECT 
    full_name,
    name_count,
    unique_emails,
    CASE 
        WHEN name_count > 1 THEN 'Duplicate'
        ELSE 'Unique'
    END AS name_status
FROM 
    AggregatedData
WHERE 
    row_num <= 100 AND unique_emails > 0
ORDER BY 
    full_name;
