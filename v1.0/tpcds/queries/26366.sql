
SELECT 
    ca_city,
    ca_state,
    COUNT(c_customer_sk) AS customer_count,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    STRING_AGG(CONCAT(c_first_name, ' ', c_last_name) ORDER BY c_last_name) AS customer_names,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(cd_dep_count) AS min_dependents,
    MAX(cd_dep_count) AS max_dependents
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
WHERE 
    ca_city IS NOT NULL AND ca_state IS NOT NULL 
GROUP BY 
    ca_city, ca_state
HAVING 
    COUNT(c_customer_sk) > 10
ORDER BY 
    ca_state, ca_city;
