
SELECT 
    CONCAT_WS(', ', c.c_first_name, c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_paid) AS average_sales,
    MAX(ws.ws_net_profit) AS maximum_profit,
    MIN(ws.ws_net_profit) AS minimum_profit,
    SUBSTRING(CAST(ws.ws_net_paid AS CHAR), 1, 5) AS truncated_net_paid
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    full_name, ca.ca_city, ca.ca_state
HAVING 
    total_orders > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
