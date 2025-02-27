
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(COALESCE(ca.ca_street_number, ''), ' ', COALESCE(ca.ca_street_name, ''), ' ', COALESCE(ca.ca_street_type, ''), 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    gender,
    COUNT(*) AS total_customers,
    AVG(CASE WHEN rank <= 5 THEN 1 ELSE 0 END) * 100 AS top_customers_percentage,
    STRING_AGG(full_name || ' - ' || full_address, '; ') AS top_customers_details
FROM (
    SELECT 
        cd_gender AS gender,
        full_name,
        full_address,
        rank
    FROM 
        RankedCustomers
) ranked
GROUP BY 
    gender
ORDER BY 
    gender;
