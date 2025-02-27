
SELECT 
    c_first_name || ' ' || c_last_name AS full_name,
    ca_city,
    ca_state,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 AND
    (ca.city ILIKE '%New%' OR ca.state ILIKE '%CA%')
GROUP BY 
    c_first_name, c_last_name, ca_city, ca_state
HAVING 
    SUM(ws_net_profit) > 1000
ORDER BY 
    total_profit DESC
LIMIT 10;
