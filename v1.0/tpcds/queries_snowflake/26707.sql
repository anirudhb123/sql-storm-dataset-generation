
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    LISTAGG(DISTINCT i.i_item_desc, '; ') WITHIN GROUP (ORDER BY i.i_item_desc) AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 1995
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_orders DESC, total_quantity DESC
LIMIT 10;
