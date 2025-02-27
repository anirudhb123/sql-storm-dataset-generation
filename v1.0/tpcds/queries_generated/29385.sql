
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(cd_dep_count) AS total_dependent_count,
    SUM(cd_purchase_estimate) AS total_purchase_estimate,
    GROUP_CONCAT(DISTINCT CD.cd_demo_sk ORDER BY CD.cd_demo_sk) AS demo_sk_list
FROM 
    customer_address AS CA
JOIN 
    customer AS C ON CA.ca_address_sk = C.c_current_addr_sk
JOIN 
    customer_demographics AS CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
WHERE 
    ca_city LIKE 'San%' 
    AND ca_state = 'CA'
GROUP BY 
    ca_city, 
    ca_state
HAVING 
    unique_customers > 10
ORDER BY 
    total_purchase_estimate DESC;
