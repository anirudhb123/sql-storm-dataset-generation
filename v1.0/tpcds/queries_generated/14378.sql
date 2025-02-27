
SELECT 
    ca.city AS address_city, 
    COUNT(DISTINCT c.c_customer_id) AS unique_customer_count, 
    SUM(ws.ws_sales_price) AS total_sales 
FROM 
    customer_address ca 
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2022 
GROUP BY 
    ca.city 
ORDER BY 
    total_sales DESC 
LIMIT 10;
