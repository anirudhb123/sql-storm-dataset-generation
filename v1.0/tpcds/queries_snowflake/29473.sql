
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    LISTAGG(DISTINCT LOWER(i.i_item_desc) || ' (' || i.i_size || ')', ', ') WITHIN GROUP (ORDER BY LOWER(i.i_item_desc), i.i_size) AS purchased_items
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
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'S' 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender
HAVING 
    COUNT(ws.ws_order_number) > 5 
    AND SUM(ws.ws_sales_price) > 100.00
ORDER BY 
    total_spent DESC;
