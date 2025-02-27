
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    STRING_AGG(DISTINCT cd_education_status, ', ') AS education_levels 
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city IS NOT NULL 
GROUP BY 
    ca_city, ca_state 
ORDER BY 
    total_customers DESC 
LIMIT 10;
