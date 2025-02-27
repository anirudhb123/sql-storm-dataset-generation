
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd.cd_education_status, ', ') AS unique_education_statuses
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 100
ORDER BY 
    ca.ca_state, ca.ca_city;
