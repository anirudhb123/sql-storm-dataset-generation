
SELECT 
    CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number) AS full_address,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUBSTR(c_first_name, 1, 1) AS first_initial, 
    LENGTH(c_email_address) AS email_length
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state = 'CA'
GROUP BY 
    full_address, first_initial
HAVING 
    customer_count > 10 AND avg_purchase_estimate > 500 
ORDER BY 
    email_length DESC, full_address ASC;
