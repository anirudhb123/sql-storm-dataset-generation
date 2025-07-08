
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    LISTAGG(DISTINCT ca_city, ', ') AS cities_list,
    LISTAGG(DISTINCT w_warehouse_name, ', ') AS warehouses_list
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store s ON c.c_current_addr_sk = s.s_store_sk
JOIN 
    warehouse w ON s.s_store_sk = w.w_warehouse_sk
GROUP BY 
    ca_state, cd_gender, cd_purchase_estimate
HAVING 
    COUNT(DISTINCT c_customer_id) > 50
ORDER BY 
    total_customers DESC;
