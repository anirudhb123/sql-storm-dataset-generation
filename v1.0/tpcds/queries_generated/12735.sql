
SELECT 
    c.c_customer_id, 
    COUNT(ss.ticket_number) AS total_store_sales,
    SUM(ss.sales_price) AS total_sales_amount,
    AVG(ss.sales_price) AS average_sales_price,
    MAX(ss.sales_price) AS max_sales_price,
    MIN(ss.sales_price) AS min_sales_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
