
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT w.web_site_id) AS total_websites,
    SUM(ws.ws_net_paid) AS total_spent,
    ARRAY_AGG(DISTINCT p.p_promo_name) AS promotions_used,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS items_purchased_desc
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    web_page w ON ws.ws_web_page_sk = w.wp_web_page_sk
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 10;
