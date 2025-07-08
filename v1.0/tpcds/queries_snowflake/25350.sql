
SELECT 
    ca.ca_country, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers, 
    SUM(ws.ws_net_paid) AS total_sales, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate, 
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_country LIKE 'United%'
GROUP BY 
    ca.ca_country
ORDER BY 
    total_sales DESC, 
    total_customers DESC
LIMIT 10;
