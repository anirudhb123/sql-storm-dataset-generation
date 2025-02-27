
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_items,
    DATE_TRUNC('month', d.d_date) AS purchase_month
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, DATE_TRUNC('month', d.d_date)
HAVING 
    SUM(ws.ws_net_paid) > 500
ORDER BY 
    total_spent DESC;
