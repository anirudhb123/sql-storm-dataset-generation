
WITH Address_Comparison AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
Customer_Analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LENGTH(c.c_email_address) AS email_length,
        SUBSTRING_INDEX(c.c_email_address, '@', -1) AS email_domain,
        SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
        SUBSTRING(c.c_last_name, 1, 1) AS last_initial
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Address_Stats AS (
    SELECT 
        AVG(address_length) AS avg_address_length,
        MIN(address_length) AS min_address_length,
        MAX(address_length) AS max_address_length
    FROM 
        Address_Comparison
),
Gender_Stats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(email_length) AS avg_email_length
    FROM 
        Customer_Analysis
    GROUP BY 
        cd_gender
)
SELECT 
    A.avg_address_length,
    A.min_address_length,
    A.max_address_length,
    G.cd_gender,
    G.gender_count,
    G.avg_email_length
FROM 
    Address_Stats A
JOIN 
    Gender_Stats G ON 1=1
ORDER BY 
    G.gender_count DESC, G.avg_email_length DESC;
