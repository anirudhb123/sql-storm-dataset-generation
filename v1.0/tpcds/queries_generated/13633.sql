
SELECT 
    c.c_customer_id,
    COUNT(ss.ticket_number) AS total_sales,
    SUM(ss.net_profit) AS total_profit,
    AVG(ss.sales_price) AS avg_sales_price,
    SUM(ss.ext_discount_amt) AS total_discount
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
