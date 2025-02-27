
SELECT 
    ca.city,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(ss.net_paid) AS total_sales,
    AVG(ss.net_profit) AS average_profit
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store s ON c.c_customer_sk = s.s_store_sk
JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca.city
ORDER BY 
    total_sales DESC;
