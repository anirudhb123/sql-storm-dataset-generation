
SELECT 
    ca.city AS address_city, 
    ca.state AS address_state, 
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    COUNT(DISTINCT CASE WHEN cd.education_status LIKE 'Bachelor%' THEN c.customer_id END) AS bachelor_customers,
    COUNT(DISTINCT CASE WHEN cd.education_status LIKE 'Graduate%' THEN c.customer_id END) AS graduate_customers,
    AVG(cd.purchase_estimate) AS average_purchase_estimate,
    MAX(cd.credit_rating) AS highest_credit_rating
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL AND 
    ca.state IN ('NY', 'CA', 'TX') 
GROUP BY 
    ca.city, ca.state
ORDER BY 
    total_customers DESC
LIMIT 10;
