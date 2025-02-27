
SELECT 
    ca.city, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(LENGTH(c.c_first_name) + LENGTH(c.c_last_name)) AS total_name_length,
    AVG(LENGTH(ca.ca_street_name)) AS avg_street_name_length,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    MAX(c.c_birth_year) AS latest_birth_year
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    customer_count DESC;
