
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(cd.cd_gender, ' - ', cd.cd_demo_sk), ', ') WITHIN GROUP (ORDER BY cd.cd_gender) AS gender_distribution,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
    COUNT(DISTINCT CASE WHEN ca.ca_state = 'CA' THEN c.c_customer_id END) AS customers_in_CA
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND cd.cd_purchase_estimate > 0
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
