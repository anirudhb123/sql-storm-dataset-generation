
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT i.i_product_name, '; ') AS purchased_items,
    COUNT(DISTINCT CASE WHEN ws.ws_sales_price > 500 THEN ws.ws_order_number END) AS high_value_orders
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    a.ca_state IN ('CA', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 1990
    AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 100;
