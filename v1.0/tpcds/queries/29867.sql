
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(ws.ws_order_number) as total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    d.d_year
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
WHERE 
    c.c_birth_month = 12 AND 
    (ws.ws_net_paid_inc_tax - ws.ws_ext_discount_amt) > 100
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, d.d_year
HAVING 
    SUM(ws.ws_net_profit) > 500
ORDER BY 
    total_orders DESC, total_profit DESC;
