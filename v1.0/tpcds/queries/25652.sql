
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    STRING_AGG(DISTINCT i.i_item_desc, '; ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IS NOT NULL 
    AND cd.cd_gender IN ('M', 'F')
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC;
