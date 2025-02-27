
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    MAX(ws.ws_ext_sales_price) AS max_order_value,
    MIN(ws.ws_ext_sales_price) AS min_order_value,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    c.cd_gender, 
    c.cd_marital_status
HAVING 
    COUNT(ws.ws_order_number) > 10
ORDER BY 
    total_sales DESC
LIMIT 100;
