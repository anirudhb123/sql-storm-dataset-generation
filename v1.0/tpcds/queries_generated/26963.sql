
SELECT 
    ca.city AS customer_city,
    COUNT(CASE WHEN cd.gender = 'F' THEN 1 END) AS female_count,
    COUNT(CASE WHEN cd.gender = 'M' THEN 1 END) AS male_count,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.credit_rating) AS highest_credit_rating,
    STRING_AGG(CONCAT(c.first_name, ' ', c.last_name), ', ') AS top_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.city IS NOT NULL
GROUP BY 
    ca.city
ORDER BY 
    female_count DESC, male_count DESC
LIMIT 10;
