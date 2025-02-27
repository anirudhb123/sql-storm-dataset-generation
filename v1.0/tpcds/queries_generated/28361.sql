
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_marital_status, 
    cd.cd_gender, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_sales_price) AS total_spent, 
    AVG(ws.ws_sales_price) AS avg_spent_per_order,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id, full_name, ca.ca_city, ca.ca_state, cd.cd_marital_status, cd.cd_gender
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
