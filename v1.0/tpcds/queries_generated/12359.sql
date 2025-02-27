
SELECT 
    ca.city, 
    COUNT(DISTINCT c.customer_id) AS customer_count, 
    SUM(ss.ext_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.state = 'CA' 
    AND ss.sold_date_sk BETWEEN 2450000 AND 2450050 
GROUP BY 
    ca.city
ORDER BY 
    total_sales DESC
LIMIT 10;
