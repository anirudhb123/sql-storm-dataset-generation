
SELECT 
    s_store_name, 
    SUM(ss_sales_price) AS total_sales, 
    COUNT(ss_ticket_number) AS total_tickets 
FROM 
    store_sales 
JOIN 
    store ON store_store_sk = ss_store_sk 
WHERE 
    ss_sold_date_sk BETWEEN 2451545 AND 2451550 
GROUP BY 
    s_store_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
