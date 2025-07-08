
SELECT 
    CA.ca_city,
    CA.ca_state,
    COUNT(DISTINCT C.c_customer_id) AS customer_count,
    SUM(CD.cd_purchase_estimate) AS total_purchase_estimate,
    AVG(CD.cd_dep_count) AS avg_dependency_count,
    LISTAGG(DISTINCT CD.cd_gender, ', ') WITHIN GROUP (ORDER BY CD.cd_gender) AS gender_distribution,
    LISTAGG(DISTINCT CD.cd_marital_status, ', ') WITHIN GROUP (ORDER BY CD.cd_marital_status) AS marital_status_distribution
FROM 
    customer_address CA
JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
WHERE 
    CA.ca_city IS NOT NULL AND 
    CA.ca_state IN ('CA', 'NY', 'TX') 
GROUP BY 
    CA.ca_city, CA.ca_state
HAVING 
    COUNT(DISTINCT C.c_customer_id) > 10
ORDER BY 
    total_purchase_estimate DESC;
