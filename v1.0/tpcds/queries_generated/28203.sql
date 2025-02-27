
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE 
            WHEN cd.cd_gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_customers,
    SUM(CASE 
            WHEN cd.cd_marital_status = 'M' THEN 1 
            ELSE 0 
        END) AS married_customers,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    ca.ca_city
ORDER BY 
    total_customers DESC
LIMIT 10;
