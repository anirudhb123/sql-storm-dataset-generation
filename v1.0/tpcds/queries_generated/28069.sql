
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    COUNT(DISTINCT c.customer_id) AS unique_customers,
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    MIN(cd.credit_rating) AS lowest_credit_rating,
    MAX(cd.credit_rating) AS highest_credit_rating
FROM 
    customer c
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL 
    AND ca.state IS NOT NULL 
GROUP BY 
    ca.city, ca.state
ORDER BY 
    unique_customers DESC, address_state ASC, address_city ASC;
