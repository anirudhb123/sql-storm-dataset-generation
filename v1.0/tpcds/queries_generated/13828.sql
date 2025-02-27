
SELECT 
    ca.city AS address_city, 
    COUNT(DISTINCT cs.order_number) AS total_catalog_sales, 
    SUM(cs.net_profit) AS total_net_profit 
FROM 
    customer_address ca 
JOIN 
    customer c ON c.current_addr_sk = ca.ca_address_sk 
JOIN 
    catalog_sales cs ON cs.bill_customer_sk = c.c_customer_sk 
JOIN 
    date_dim d ON cs.sold_date_sk = d.d_date_sk 
WHERE 
    d.year = 2023 
GROUP BY 
    ca.city 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
