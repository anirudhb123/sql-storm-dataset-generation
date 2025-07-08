
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    MAX(ws.ws_ext_sales_price) AS max_sales_price,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used,
    COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c.c_customer_sk END) AS male_customers,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c.c_customer_sk END) AS female_customers
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    LOWER(ca.ca_city) LIKE '%spring%'
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    max_sales_price DESC
LIMIT 10;
