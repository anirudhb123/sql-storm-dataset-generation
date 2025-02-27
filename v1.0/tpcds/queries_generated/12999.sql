
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ticket_number) AS store_sales_count,
    SUM(ss.net_paid) AS total_store_sales,
    SUM(ss.ext_discount_amt) AS total_discount,
    d.d_year,
    d.d_month_seq
FROM 
    store_sales ss
JOIN 
    customer c ON ss.customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ss.sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, d.d_year, d.d_month_seq
ORDER BY 
    total_store_sales DESC
LIMIT 100;
