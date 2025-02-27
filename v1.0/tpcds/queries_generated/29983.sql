
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    GROUP_CONCAT(DISTINCT i.i_item_desc ORDER BY i.i_item_desc SEPARATOR '; ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    c.c_birth_month = 12 AND 
    c.c_birth_day BETWEEN 20 AND 31 
GROUP BY 
    c.c_customer_id, full_name, ca.ca_city, ca.ca_state
HAVING 
    total_orders > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
