
SELECT 
    c.c_customer_id,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    DATEDIFF(DAY, MIN(d.d_date), MAX(d.d_date)) AS active_days
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
