
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    GROUP_CONCAT(DISTINCT p.p_promo_name ORDER BY p.p_promo_name ASC SEPARATOR ', ') AS promotions_used
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    total_quantity_sold > 0
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
