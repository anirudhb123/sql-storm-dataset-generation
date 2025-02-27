
SELECT 
    ca.state AS address_state, 
    COUNT(DISTINCT c.customer_id) AS total_customers, 
    SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_customers, 
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.dep_count) AS max_dependencies,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.state IS NOT NULL
GROUP BY 
    ca.state
ORDER BY 
    total_customers DESC
LIMIT 10;
