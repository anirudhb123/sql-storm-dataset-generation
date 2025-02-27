
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    CD.cd_marital_status, 
    CD.cd_gender, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS products_ordered
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city LIKE '%Springfield%'
    AND CD.cd_marital_status = 'M'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    CD.cd_marital_status, 
    CD.cd_gender
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 50;
