
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END, 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        Address_Concat a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    CONCAT('Address: ', c.full_address) AS complete_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    COUNT(*) OVER (PARTITION BY d.cd_gender, d.cd_marital_status, d.cd_education_status) AS demographic_count
FROM 
    Customer_Info c
JOIN 
    date_dim d ON d.d_date_sk = CAST(DATE_FORMAT(CURRENT_DATE, '%Y%m%d') AS UNSIGNED)
WHERE 
    c.cd_gender = 'F' AND 
    c.cd_marital_status = 'M'
ORDER BY 
    c.full_address;
