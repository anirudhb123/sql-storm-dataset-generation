
SELECT 
    c.c_customer_id, 
    COUNT(DISTINCT w.ws_order_number) AS total_orders, 
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE 
    w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA')
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_spent DESC
LIMIT 100;
