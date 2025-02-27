
WITH formatted_addresses AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), ''), 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_address_sk
    FROM 
        customer_address
),
demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status, 
        COUNT(*) AS demo_count
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    fa.full_address, 
    d.gender_marital_status, 
    d.demo_count
FROM 
    formatted_addresses fa
JOIN 
    customer c ON fa.ca_address_sk = c.c_current_addr_sk
JOIN 
    demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    d.cd_education_status LIKE '%College%'
ORDER BY 
    d.demo_count DESC
LIMIT 50;
