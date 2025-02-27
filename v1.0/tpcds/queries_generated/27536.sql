
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    MAX(ws.ws_ship_date_sk) AS last_order_date,
    STRING_AGG(DISTINCT sm.sm_type || ' - ' || sm.sm_carrier) AS ship_modes_used,
    STRING_AGG(DISTINCT i.i_product_name) AS products_ordered
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    ca.ca_city ILIKE '%Springfield%' 
    AND ca.ca_state = 'IL'
    AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
