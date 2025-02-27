
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers, 
    SUM(ws_net_profit) AS total_profit 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    web_sales ON c_customer_sk = ws_ship_customer_sk 
WHERE 
    d_year = 2023 
GROUP BY 
    ca_state 
ORDER BY 
    total_profit DESC 
LIMIT 10;
