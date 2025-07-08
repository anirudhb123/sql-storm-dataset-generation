
SELECT 
    c.c_first_name,
    c.c_last_name,
    CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS average_order_value,
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS marital_customers,
    LENGTH(c.c_email_address) AS email_length
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, c.c_salutation, c.c_email_address, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
