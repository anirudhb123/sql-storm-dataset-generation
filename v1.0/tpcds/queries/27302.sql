
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'TX') AND
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
