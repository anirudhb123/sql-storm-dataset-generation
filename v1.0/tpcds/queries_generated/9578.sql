
SELECT 
    ca.city AS address_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid_inc_tax) AS average_net_paid,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    d.d_year AS sales_year
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    ca.ca_country = 'USA'
    AND d.d_year BETWEEN 2021 AND 2023 
GROUP BY 
    ca.city, d.d_year
ORDER BY 
    total_profit DESC, customer_count DESC
LIMIT 100;
