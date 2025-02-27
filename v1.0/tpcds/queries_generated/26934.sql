
SELECT 
    c.c_customer_id AS customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    GROUP_CONCAT(DISTINCT i.i_product_name ORDER BY i.i_product_name SEPARATOR ', ') AS purchased_products,
    DATE_FORMAT(DATE_ADD(DATE(d.d_date), INTERVAL RAND() * 30 DAY), '%Y-%m-%d') AS random_future_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_month = MONTH(NOW()) AND 
    c.c_birth_day = DAY(NOW())
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    total_orders > 0
ORDER BY 
    total_spent DESC;
