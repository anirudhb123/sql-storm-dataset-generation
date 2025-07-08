
SELECT 
    ca.ca_street_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cu.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cu.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    AVG(cu.cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name) AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cu ON c.c_current_cdemo_sk = cu.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX') 
    AND cu.cd_marital_status = 'M'
GROUP BY 
    ca.ca_street_name, ca.ca_city, ca.ca_state
ORDER BY 
    customer_count DESC, ca.ca_city;
