
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS average_order_value,
    DATE_FORMAT(DATE(d.d_date), '%Y-%m') AS order_month
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, order_month
HAVING 
    total_orders > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
