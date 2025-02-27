
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.city
ORDER BY 
    total_sales DESC
LIMIT 10;
