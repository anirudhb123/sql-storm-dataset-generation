
SELECT 
    ca.city AS address_city, 
    ca.state AS address_state, 
    cd.gender AS demographic_gender, 
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN c.c_birth_month = 12 THEN 1 ELSE 0 END) AS customers_born_in_december,
    STRING_AGG(CONCAT(c.first_name, ' ', c.last_name), '; ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.country = 'USA'
    AND cd.education_status IN ('Bachelor\'s', 'Master\'s', 'PhD')
GROUP BY 
    ca.city, ca.state, cd.gender
ORDER BY 
    total_customers DESC, address_city ASC;
