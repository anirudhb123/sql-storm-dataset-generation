
SELECT 
    ca.city,
    ca.state,
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    STRING_AGG(DISTINCT c.first_name || ' ' || c.last_name, ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL AND ca.state IS NOT NULL
GROUP BY 
    ca.city,
    ca.state
HAVING 
    total_customers > 10
ORDER BY 
    ca.state, 
    ca.city;
