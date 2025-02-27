
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') AS customer_names
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IS NOT NULL
GROUP BY 
    ca_state
ORDER BY 
    unique_customers DESC;
