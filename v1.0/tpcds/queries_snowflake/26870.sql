
SELECT 
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    SUM(ws.ws_net_profit) AS total_profit,
    LISTAGG(DISTINCT w.web_name, ', ') AS websites_used,
    LISTAGG(DISTINCT CONCAT(p.p_promo_name, ' (', p.p_channel_details, ')'), '; ') AS promotions_used
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
LEFT JOIN 
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 50;
