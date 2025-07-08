
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    COUNT(DISTINCT ca.ca_city) AS unique_cities,
    SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
    UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
    LISTAGG(CONCAT(c.c_first_name, ' ', c.c_last_name), '; ') WITHIN GROUP (ORDER BY c.c_customer_id) AS all_customers,
    MAX(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_purchase_estimate END) AS max_married_purchase_estimate,
    MIN(CASE WHEN cd.cd_marital_status = 'S' THEN cd.cd_purchase_estimate END) AS min_single_purchase_estimate
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    cd.cd_purchase_estimate > 1000
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_customers DESC
LIMIT 100;
