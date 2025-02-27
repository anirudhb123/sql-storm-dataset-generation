
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(cd_credit_rating) AS average_credit_rating,
    COUNT(DISTINCT ws_order_number) AS total_orders
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    ca_state
HAVING 
    SUM(ws_net_profit) > 10000
ORDER BY 
    total_net_profit DESC
LIMIT 10;
