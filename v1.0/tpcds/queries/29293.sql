
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    MIN(d.d_date) AS first_order_date,
    MAX(d.d_date) AS last_order_date,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS used_promotions,
    SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1, CHAR_LENGTH(c.c_email_address)) AS email_domain,
    LENGTH(c.c_email_address) AS email_length
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX') 
    AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state,
    email_domain, email_length
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 100;
