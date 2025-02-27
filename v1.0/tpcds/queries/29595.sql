
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_paid) AS total_web_spent,
    SUM(CASE WHEN ws.ws_sales_price > 50 THEN 1 ELSE 0 END) AS total_high_value_orders,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_web_spent DESC
LIMIT 100;
