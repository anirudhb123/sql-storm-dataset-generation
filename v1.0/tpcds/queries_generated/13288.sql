
SELECT 
    c.c_customer_id,
    COUNT(ss.ticket_number) AS total_sales,
    SUM(ss.net_paid) AS total_revenue,
    AVG(ss.net_paid) AS average_sale,
    MAX(ss.net_paid) AS largest_sale
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 100;
