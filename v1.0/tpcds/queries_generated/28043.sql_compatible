
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.cd_credit_rating) AS highest_credit_rating,
    STRING_AGG(DISTINCT cd.cd_marital_status, ', ') AS marital_status_distribution
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('NY', 'CA', 'TX')
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    customer_count DESC, 
    ca.ca_city
LIMIT 100;
