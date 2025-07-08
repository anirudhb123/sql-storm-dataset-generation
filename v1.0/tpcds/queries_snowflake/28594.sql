
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd_gender = 'F' THEN cd_dep_count ELSE 0 END) AS female_dependents,
    SUM(CASE WHEN c_birth_year BETWEEN 1980 AND 2000 THEN 1 ELSE 0 END) AS millennials_count,
    LISTAGG(DISTINCT ca_street_name || ' ' || ca_street_number, ', ') AS unique_addresses
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    avg_purchase_estimate DESC;
