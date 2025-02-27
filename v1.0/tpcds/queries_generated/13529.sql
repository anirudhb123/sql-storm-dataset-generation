
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(cs.cs_sales_price) AS total_sales,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(cs.cs_order_number) AS order_count
FROM 
    customer c
JOIN 
    store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
JOIN 
    date_dim d ON cs.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 10;
