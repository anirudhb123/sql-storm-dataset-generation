
SELECT 
    ca_city, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count, 
    STRING_AGG(DISTINCT c.c_last_name, ', ') AS customer_last_names,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_full_names,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(cd_purchase_estimate) AS total_purchase_estimate
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca_state = 'CA' 
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
