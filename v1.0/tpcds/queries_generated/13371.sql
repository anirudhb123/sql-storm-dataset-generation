
SELECT 
    c.c_customer_id,
    SUM(ss.net_profit) AS total_net_profit,
    COUNT(ss.ticket_number) AS total_sales,
    DATE(d.d_date) AS sale_date
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, DATE(d.d_date)
ORDER BY 
    total_net_profit DESC
LIMIT 100;
