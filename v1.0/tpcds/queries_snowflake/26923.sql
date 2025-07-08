
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    LISTAGG(DISTINCT CONCAT(ws.ws_order_number, ' (', ws.ws_sold_date_sk, ')'), ', ') AS order_details,
    TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
    LOWER(CONCAT(ca.ca_city, '_', ca.ca_state)) AS location_tag
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND c.c_birth_year BETWEEN 1980 AND 1995
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_net_profit) > 0
ORDER BY 
    total_net_profit DESC, full_name ASC;
