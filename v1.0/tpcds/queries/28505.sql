
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_items,
    MAX(d.d_date) AS last_purchase_date 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.cd_gender = 'F' AND 
    ca.ca_state IN ('CA', 'NY') 
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state, cd.cd_gender, c.c_first_name, c.c_last_name 
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 
ORDER BY 
    total_spent DESC;
