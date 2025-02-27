
SELECT 
    LOWER(CONCAT(CAST(c.c_first_name AS VARCHAR), ' ', CAST(c.c_last_name AS VARCHAR))) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(TO_CHAR(d.d_date, 'Month YYYY')) AS sales_month
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    full_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
