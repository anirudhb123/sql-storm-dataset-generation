
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS avg_spent_per_order,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC;
