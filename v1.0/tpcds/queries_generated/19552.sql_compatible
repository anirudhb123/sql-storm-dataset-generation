
SELECT 
    ca.city,
    COUNT(DISTINCT c.c_customer_id) AS number_of_customers,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
GROUP BY 
    ca.city
ORDER BY 
    total_sales DESC;
