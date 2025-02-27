
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(LENGTH(ca.ca_street_name)) AS total_street_name_length,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_street_name_length DESC, unique_customers DESC
LIMIT 100;
