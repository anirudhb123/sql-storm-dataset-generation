
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    w.w_warehouse_name,
    sm.sm_type,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(LENGTH(c.c_email_address)) AS avg_email_length,
    STRING_AGG(DISTINCT CONCAT(i.i_product_name, ' (', i.i_item_desc, ')'), ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ca.ca_state IS NOT NULL
    AND ws.ws_sales_price > 0
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, w.w_warehouse_name, sm.sm_type
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY 
    total_sales DESC
LIMIT 100;
