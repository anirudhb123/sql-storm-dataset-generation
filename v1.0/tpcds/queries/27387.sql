
SELECT 
    SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
    c.c_last_name AS last_name,
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_revenue,
    AVG(i.i_current_price) AS avg_item_price,
    MAX(i.i_current_price) AS max_item_price,
    MIN(i.i_current_price) AS min_item_price,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promo_list
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_city LIKE '%ville%'
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 100;
