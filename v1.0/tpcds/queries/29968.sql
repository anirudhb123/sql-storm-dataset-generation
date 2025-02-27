
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS address,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    COUNT(*) AS total_customers,
    MIN(rn) AS min_rank,
    MAX(rn) AS max_rank,
    AVG(rn) AS avg_rank,
    STRING_AGG(full_name ORDER BY full_name) AS customer_names
FROM 
    RankedCustomers
WHERE 
    cd_gender = 'F' AND 
    cd_marital_status = 'M'
GROUP BY 
    cd_education_status
ORDER BY 
    total_customers DESC;
