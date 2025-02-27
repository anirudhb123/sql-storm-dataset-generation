
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    cd.gender AS customer_gender,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN cd.marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    SUM(CASE WHEN cd.education_status LIKE '%Bachelor%' THEN 1 ELSE 0 END) AS bachelor_degree_customers,
    MAX(CAST(SUBSTRING(c.first_name, 1, 2) AS VARCHAR) || ' ' || 
        CAST(SUBSTRING(c.last_name, 1, 3) AS VARCHAR)) AS initials,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT ca.street_name, ', ') AS street_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL 
    AND ca.state IS NOT NULL 
    AND cd.purchase_estimate > 0
GROUP BY 
    ca.city, 
    ca.state, 
    cd.gender
ORDER BY 
    total_customers DESC
LIMIT 100;
