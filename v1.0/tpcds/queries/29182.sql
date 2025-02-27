
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS unique_customers, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count, 
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count, 
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state = 'CA' 
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    unique_customers DESC;
