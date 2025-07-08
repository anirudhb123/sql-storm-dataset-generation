
SELECT 
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    ca.ca_city AS city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    LISTAGG(DISTINCT CONCAT(ws.ws_ship_mode_sk, ': ', sm.sm_type), '; ') AS shipping_methods,
    d.d_date AS last_order_date
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_date >= CAST('2002-10-01' AS DATE) - INTERVAL '1 year'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, d.d_date
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
