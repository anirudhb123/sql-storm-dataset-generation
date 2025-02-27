
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_id) AS customer_count, 
    AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
    SUM(ws_net_sales) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
