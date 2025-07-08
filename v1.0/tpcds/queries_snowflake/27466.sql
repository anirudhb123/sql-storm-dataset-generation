
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    LISTAGG(DISTINCT CONCAT(cd.cd_education_status, ': ', cd.cd_marital_status), '; ') AS demographics_summary
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('NY', 'CA')
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
