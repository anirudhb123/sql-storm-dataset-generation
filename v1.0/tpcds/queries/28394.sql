
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    STRING_AGG(CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name), ', ') AS customer_names,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca_city, ca_state
ORDER BY 
    unique_customers DESC;
