
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city || ', ' || ca.ca_state AS full_address,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    AVG(ws.ws_net_profit) AS avg_profit,
    LISTAGG(DISTINCT i.i_product_name, ', ') WITHIN GROUP (ORDER BY i.i_product_name) AS purchased_products,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS city_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_country = 'USA' AND 
    c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_ext_sales_price) > 500
ORDER BY 
    total_spent DESC
LIMIT 100;
