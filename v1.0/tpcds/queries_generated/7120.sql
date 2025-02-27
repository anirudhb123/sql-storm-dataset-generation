
SELECT 
    c.c_first_name AS customer_first_name,
    c.c_last_name AS customer_last_name,
    ca.ca_city AS customer_city,
    SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    d.d_year AS purchase_year,
    COUNT(DISTINCT CASE WHEN sm.sm_type = 'AIR' THEN ss.ss_ticket_number END) AS air_shipment_count,
    COUNT(DISTINCT CASE WHEN sm.sm_type = 'GROUND' THEN ws.ws_order_number END) AS ground_shipment_count
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON d.d_date_sk = ss.ss_sold_date_sk OR d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    ship_mode AS sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk OR sm.sm_ship_mode_sk = ss.ss_promo_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, d.d_year
ORDER BY 
    total_spent DESC
LIMIT 100;
