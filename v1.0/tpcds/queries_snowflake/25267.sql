
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count, 
    LISTAGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') WITHIN GROUP (ORDER BY c.c_customer_id) AS customer_names,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    AVG(ws.ws_sales_price) AS average_sales_price,
    MAX(ws.ws_net_profit) AS max_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 AND 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    customer_count DESC, total_sales_quantity DESC
LIMIT 10;
