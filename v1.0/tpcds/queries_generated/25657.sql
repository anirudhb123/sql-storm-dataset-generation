
SELECT 
    ca.city AS address_city, 
    ca.state AS address_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    AVG(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_ratio,
    AVG(CASE WHEN cd.education_status LIKE '%College%' THEN 1 ELSE 0 END) AS college_ratio,
    SUM(CASE WHEN ca.city LIKE '%San%' THEN 1 ELSE 0 END) AS san_city_count,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS top_customers
FROM 
    customer_address ca
JOIN 
    customer c ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.state IN ('CA', 'NY')
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT c.customer_id) > 10
ORDER BY 
    total_customers DESC;
