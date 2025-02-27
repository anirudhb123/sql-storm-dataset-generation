
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(cs.cs_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
