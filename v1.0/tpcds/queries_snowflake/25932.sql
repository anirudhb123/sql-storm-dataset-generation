
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used,
    COUNT(DISTINCT wp.wp_url) AS distinct_web_pages_visited
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sold_date_sk >= 2459215 
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC;
