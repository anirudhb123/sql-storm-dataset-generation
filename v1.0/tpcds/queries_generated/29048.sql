
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count, 
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_status_distribution,
    STRING_AGG(DISTINCT cd_education_status, ', ') AS education_distribution
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_city, ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    avg_purchase_estimate DESC;
