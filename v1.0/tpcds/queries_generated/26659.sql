
SELECT 
    ca.city AS city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    GROUP_CONCAT(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name) ORDER BY c.c_last_name SEPARATOR ', ') AS customer_names,
    GROUP_CONCAT(DISTINCT ca.ca_street_name ORDER BY ca.ca_street_name SEPARATOR ', ') AS street_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL AND 
    ca.ca_state = 'CA' 
GROUP BY 
    ca.city
HAVING 
    unique_customers > 10
ORDER BY 
    unique_customers DESC;
