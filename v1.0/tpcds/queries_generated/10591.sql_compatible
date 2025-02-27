
SELECT 
    c.c_gender,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    c.c_gender
ORDER BY 
    total_sales DESC;
