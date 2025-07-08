
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS full_address,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS avg_order_value,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value,
    LISTAGG(DISTINCT i.i_item_desc, ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS purchased_items
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
