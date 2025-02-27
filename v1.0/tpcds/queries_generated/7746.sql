
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ws.net_profit) AS total_net_profit,
    AVG(cd.purchase_estimate) AS average_purchase_estimate,
    DATE(d.d_date) AS sale_date
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND ca.ca_state = 'CA'
    AND ws.net_profit > 1000
GROUP BY 
    ca.city, d.d_date
ORDER BY 
    total_net_profit DESC, customer_count DESC
LIMIT 10;
