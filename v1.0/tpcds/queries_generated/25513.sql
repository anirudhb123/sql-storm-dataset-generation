
SELECT 
    CA.ca_city AS city,
    COUNT(DISTINCT C.c_customer_id) AS customer_count,
    AVG(CD.cd_dep_count) AS average_dependents,
    SUM(CASE WHEN CD.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN CD.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    STRING_AGG(DISTINCT CONCAT(CD.cd_marital_status, ' - ', CD.cd_education_status) ORDER BY CD.cd_marital_status) AS demographic_composition,
    SUM(CASE WHEN W.w_warehouse_name IS NOT NULL THEN 1 ELSE 0 END) AS warehouses_active
FROM 
    customer C
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    inventory I ON I.inv_quantity_on_hand > 0
LEFT JOIN 
    warehouse W ON I.inv_warehouse_sk = W.w_warehouse_sk
GROUP BY 
    CA.ca_city
HAVING 
    COUNT(DISTINCT C.c_customer_id) > 10
ORDER BY 
    customer_count DESC;
