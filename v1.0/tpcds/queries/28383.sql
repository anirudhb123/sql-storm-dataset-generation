
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    STRING_AGG(DISTINCT CONCAT(wp.wp_url, ' (', wp.wp_type, ')'), ', ') AS visited_web_pages
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC;
