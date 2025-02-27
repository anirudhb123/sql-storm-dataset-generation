
WITH address_summary AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_country
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_summary ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.full_address,
    asum.address_count
FROM 
    customer_info ci
JOIN 
    address_summary asum ON ci.full_address = asum.full_address
WHERE 
    ci.cd_gender = 'F' AND 
    ci.cd_marital_status = 'M'
ORDER BY 
    asum.address_count DESC, 
    ci.full_name
LIMIT 100;
