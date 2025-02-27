
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COUNT(DISTINCT ws.ws_web_page_id) AS total_web_pages,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT w.w_warehouse_name, ', ') AS warehouses_in_city,
    STRING_AGG(DISTINCT CONCAT(cd.cd_marital_status, ' ', cd.cd_gender), ', ' ORDER BY cd.cd_marital_status) AS marital_gender_combinations
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    warehouse w ON w.w_warehouse_sk IN (SELECT DISTINCT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_customers DESC, ca.ca_city;
