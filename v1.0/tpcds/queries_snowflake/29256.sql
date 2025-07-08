
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used,
    COALESCE(MAX(cr.cr_return_amount), 0) AS total_returns
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
WHERE ca.ca_state = 'CA' 
AND cd.cd_gender = 'F' 
AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
