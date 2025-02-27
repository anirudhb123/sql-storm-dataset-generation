
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    MAX(ws.ws_net_paid_inc_tax) AS max_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT it.i_product_name, ', ') AS purchased_items,
    COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c.c_customer_sk END) AS male_customers,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c.c_customer_sk END) AS female_customers
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item it ON ws.ws_item_sk = it.i_item_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
    AND ws.ws_sold_date_sk BETWEEN 10001 AND 10015
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    MAX(ws.ws_net_paid_inc_tax) > 100
ORDER BY 
    total_orders DESC, max_spent DESC;
