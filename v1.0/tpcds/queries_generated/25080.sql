
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    GROUP_CONCAT(DISTINCT i.i_item_desc ORDER BY i.i_item_desc SEPARATOR ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA' 
    AND c.c_birth_year BETWEEN 1980 AND 1995
    AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state
HAVING 
    total_orders > 1
ORDER BY 
    total_spent DESC
LIMIT 100;
