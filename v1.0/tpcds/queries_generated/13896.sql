
SELECT 
    c.c_customer_id,
    SUM(ws.net_paid) AS total_sales,
    COUNT(DISTINCT ws.order_number) AS total_orders,
    COUNT(DISTINCT ws.web_page_sk) AS distinct_web_pages
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
JOIN 
    date_dim d ON ws.sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
