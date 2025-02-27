
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    SUBSTRING(c.login, 1, 5) AS short_login,
    (CASE WHEN LENGTH(c.c_email_address) > 15 THEN CONCAT(SUBSTRING(c.c_email_address, 1, 10), '...') ELSE c.c_email_address END) AS email_preview,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, c.login, c.c_email_address, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type
ORDER BY 
    total_orders DESC, total_spent DESC
LIMIT 100;
