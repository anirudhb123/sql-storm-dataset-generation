
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customer_names
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'NY')
GROUP BY 
    ca_city, 
    ca_state
ORDER BY 
    total_customers DESC 
LIMIT 10;
