
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    time_dim t ON ss.ss_sold_date_sk = t.d_date_sk
WHERE 
    t.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
