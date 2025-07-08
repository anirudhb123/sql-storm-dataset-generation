
SELECT 
    ca_city,
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') AS customer_names
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
AND 
    cd_marital_status = 'M'
AND 
    cd_gender = 'F'
AND 
    ca_city IS NOT NULL
GROUP BY 
    ca_city, ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY 
    ca_city, ca_state;
