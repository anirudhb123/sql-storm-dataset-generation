
SELECT 
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    STRING_AGG(DISTINCT cd.cd_gender, ', ') AS distinct_genders
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'TX')
GROUP BY 
    ca.ca_state, ca.ca_city
ORDER BY 
    total_customers DESC;
