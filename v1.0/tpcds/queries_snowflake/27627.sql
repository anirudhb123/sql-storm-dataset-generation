
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT cd.cd_education_status, ', ') WITHIN GROUP (ORDER BY cd.cd_education_status) AS unique_education_statuses,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ca.ca_country = 'USA'
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    ca.ca_city, cd.cd_purchase_estimate, cd.cd_education_status, cd.cd_gender
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    customer_count DESC
LIMIT 20;
