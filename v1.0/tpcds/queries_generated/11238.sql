
SELECT 
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    ws.ws_web_site_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name, s.s_store_name, ws.ws_web_site_id
ORDER BY 
    total_sales DESC
LIMIT 100;
