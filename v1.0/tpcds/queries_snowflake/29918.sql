
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS average_order_value,
    MIN(ws.ws_sales_price) AS min_order_value,
    MAX(ws.ws_sales_price) AS max_order_value,
    LISTAGG(DISTINCT i.i_category, ', ') AS purchased_categories
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IS NOT NULL AND 
    (c.c_birth_year BETWEEN 1980 AND 2000)
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_country
ORDER BY 
    total_spent DESC
LIMIT 100;
