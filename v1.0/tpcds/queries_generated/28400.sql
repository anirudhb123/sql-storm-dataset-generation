
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_web_sales,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', i.i_item_desc, i.i_category, i.i_brand) ORDER BY i.i_item_desc) AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL AND 
    ca.ca_state IN ('CA', 'TX', 'NY') AND 
    c.c_birth_year >= 1980
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    total_web_sales DESC
LIMIT 100;
