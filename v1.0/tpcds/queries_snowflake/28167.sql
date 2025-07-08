
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_net_profit,
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_sales DESC
LIMIT 50;
