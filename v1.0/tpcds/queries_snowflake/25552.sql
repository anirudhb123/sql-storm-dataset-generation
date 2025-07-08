
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS num_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(cd_marital_status, ': ', cd_gender), ', ') AS gender_marital_status
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city IS NOT NULL
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_id) > 5
ORDER BY 
    num_customers DESC
LIMIT 10;
