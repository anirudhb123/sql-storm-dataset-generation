
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_item_id, ')'), '; ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city LIKE 'New%' AND 
    YEAR(ws.ws_sold_date_sk) = 2023 
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
