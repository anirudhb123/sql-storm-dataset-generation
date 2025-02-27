
SELECT 
    ca.city AS customer_city,
    ca.state AS customer_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    STRING_AGG(DISTINCT CONCAT_WS(' ', c.first_name, c.last_name), ', ') AS customer_names,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.dep_count) AS max_dependents,
    MIN(cd.dep_count) AS min_dependents,
    STRING_AGG(DISTINCT cd.education_status, ', ') AS unique_education_statuses
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL 
    AND ca.state IS NOT NULL
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT c.customer_id) > 10
ORDER BY 
    total_customers DESC, customer_city ASC;
