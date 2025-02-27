
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS avg_order_value,
    STRING_AGG(DISTINCT CONCAT('Item: ', i.i_item_desc, ' Price: ', i.i_current_price) ORDER BY i.i_item_desc) AS purchased_items,
    STRING_AGG(DISTINCT d.d_day_name ORDER BY d.d_date) AS purchase_days
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
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    AND ca.ca_state = 'CA'
    AND ws.ws_sales_price BETWEEN 10.00 AND 500.00
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY 
    total_spent DESC
LIMIT 100;
