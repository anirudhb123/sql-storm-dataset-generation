
SELECT 
    LEFT(c.c_first_name, 1) || '. ' || c.c_last_name AS customer_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    MAX(d.d_date) AS last_order_date,
    COUNT(DISTINCT CASE WHEN ws.ws_ship_mode_sk = sm.sm_ship_mode_sk THEN ws.ws_order_number END) AS distinct_ship_modes,
    LISTAGG(DISTINCT CONCAT(sc.s_store_name, ' (', sc.s_city, ', ', sc.s_state, ')'), '; ') WITHIN GROUP (ORDER BY sc.s_store_name) AS store_locations
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    store sc ON ws.ws_warehouse_sk = sc.s_store_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name
HAVING 
    SUM(ws.ws_sales_price) > (SELECT AVG(total) FROM (SELECT SUM(ws_sales_price) AS total FROM web_sales GROUP BY ws_bill_customer_sk) AS avg_spent)
ORDER BY 
    total_spent DESC;
