
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS average_order_value,
    LISTAGG(DISTINCT ip.i_product_name, ', ') WITHIN GROUP (ORDER BY ip.i_product_name) AS purchased_items,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item ip ON ws.ws_item_sk = ip.i_item_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
