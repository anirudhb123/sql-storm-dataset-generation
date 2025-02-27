
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ticket_number) AS total_store_sales,
    SUM(ss.ext_sales_price) AS total_sales_value,
    AVG(ss.ext_discount_amt) AS average_discount
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2022
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_value DESC
LIMIT 100;
