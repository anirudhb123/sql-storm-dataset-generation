
SELECT 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_net_paid) AS average_net_paid,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 1000
ORDER BY 
    unique_customers DESC;
