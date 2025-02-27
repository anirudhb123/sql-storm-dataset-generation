
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    DATE_FORMAT(d_date, '%Y-%m') AS sales_month
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND ca.city IS NOT NULL
GROUP BY 
    ca_city, sales_month
HAVING 
    total_net_profit > 1000
ORDER BY 
    total_quantity_sold DESC, total_net_profit DESC;
