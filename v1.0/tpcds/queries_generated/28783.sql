
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    SUM(ws.ws_quantity) AS total_quantity
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_orders DESC, total_profit DESC;
