
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    MIN(DATE(d.d_date)) AS first_order_date,
    MAX(DATE(d.d_date)) AS last_order_date,
    LISTAGG(DISTINCT w.w_warehouse_name, ', ') AS warehouses_used,
    LISTAGG(DISTINCT sm.sm_carrier, ', ') AS shipping_methods
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    c.c_birth_year >= 1980
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC
LIMIT 100;
