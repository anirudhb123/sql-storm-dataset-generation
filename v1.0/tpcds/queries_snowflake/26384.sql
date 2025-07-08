
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    ca.ca_zip, 
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS average_spent,
    LISTAGG(DISTINCT i.i_item_desc, '; ') WITHIN GROUP (ORDER BY i.i_item_desc) AS purchased_items,
    MAX(date_dim.d_date) AS last_purchase_date
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
    date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    ca.ca_zip, 
    cd.cd_gender
ORDER BY 
    total_orders DESC, 
    average_spent DESC
LIMIT 100;
