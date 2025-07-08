
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ws.ws_ext_sales_price) AS total_spent, 
    COUNT(ws.ws_order_number) AS total_orders,
    LISTAGG(DISTINCT i.i_item_desc, ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS purchased_items,
    MIN(d.d_date) AS first_purchase_date,
    MAX(d.d_date) AS last_purchase_date,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 1000 THEN 'VIP'
        WHEN SUM(ws.ws_ext_sales_price) > 500 THEN 'Regular'
        ELSE 'New'
    END AS customer_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(ws.ws_order_number) > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
