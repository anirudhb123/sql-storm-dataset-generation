
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(LENGTH(c_first_name || ' ' || c_last_name)) AS max_name_length,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    CONCAT(ca_city, ', ', ca_state) AS full_address,
    STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 100
ORDER BY 
    total_customers DESC;
