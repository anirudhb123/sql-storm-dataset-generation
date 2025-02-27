
SELECT 
    c.first_name, 
    c.last_name, 
    ca.city, 
    ca.state, 
    SUM(ss.ext_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.first_name, 
    c.last_name, 
    ca.city, 
    ca.state
ORDER BY 
    total_sales DESC
LIMIT 10;
