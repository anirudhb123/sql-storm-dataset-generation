
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_products
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip
ORDER BY 
    total_spent DESC
LIMIT 100;
