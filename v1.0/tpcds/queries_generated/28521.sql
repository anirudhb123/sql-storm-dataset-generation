
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    unique_customers DESC;
