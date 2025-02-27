
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promo_used,
    CONCAT(COALESCE(c.c_salutation, 'Dear'), ' ', c.c_first_name, ' ', c.c_last_name) AS customer_greeting,
    UPPER(ca.ca_country) AS country_uppercase,
    LENGTH(CONCAT(ca.ca_street_name, ' ', ca.ca_city)) AS address_length,
    (SELECT COUNT(*) FROM customer WHERE c_birth_month = 12) AS total_customers_born_in_december
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city,
    ca.ca_state,
    c.c_salutation,
    ca.ca_country,
    ca.ca_street_name
ORDER BY 
    total_spent DESC;
