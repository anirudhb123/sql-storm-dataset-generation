
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    STRING_AGG(DISTINCT CONCAT(p.p_promo_name, ' (', p.p_channel_details, ')'), ', ') AS promotions_used,
    STRING_AGG(DISTINCT CONCAT(i.i_product_name, ' (', i.i_item_desc, ')'), '; ') AS items_ordered
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
AND 
    ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 100;
