
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    ca.ca_city AS customer_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT CONCAT(wp.wp_url, ' (', wp.wp_type, ')'), '; ') AS visited_web_pages,
    MAX(d.d_date) AS last_order_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year >= 1980 
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 
ORDER BY 
    total_spent DESC
LIMIT 100;
