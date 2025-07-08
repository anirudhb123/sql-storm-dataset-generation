
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names,
    MAX(cd_demo_sk) AS max_demo_sk,
    MIN(cd_demo_sk) AS min_demo_sk
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    LOWER(ca_city) LIKE '%town%'
GROUP BY 
    ca_city
ORDER BY 
    unique_customers DESC
LIMIT 10;
