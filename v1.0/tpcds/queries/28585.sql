
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    string_agg(DISTINCT CONCAT_WS(', ', i.i_item_desc, i.i_color, i.i_size), '; ') AS purchased_items,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 2
ORDER BY 
    total_spent DESC
LIMIT 100;
