
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS used_promotions,
    CASE 
        WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 
            ROUND(SUM(ws.ws_net_paid) / COUNT(DISTINCT ws.ws_order_number), 2)
        ELSE 0
    END AS average_order_value
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
    AND c.c_birth_year BETWEEN 1970 AND 1995
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_net_paid) > 500
ORDER BY 
    total_spent DESC
LIMIT 100;
