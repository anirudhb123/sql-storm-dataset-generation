
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws_net_profit) AS total_net_profit,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names,
    COUNT(DISTINCT ws_order_number) AS total_orders
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F'
    AND ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca_state,
    cd_purchase_estimate
HAVING 
    COUNT(DISTINCT ws_order_number) > 10
ORDER BY 
    total_net_profit DESC;
