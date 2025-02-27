
SELECT 
    ca.city AS delivery_city,
    COUNT(DISTINCT ss.customer_sk) AS total_customers,
    SUM(ss.net_profit) AS total_profit,
    AVG(ss.quantity) AS avg_sales_quantity
FROM 
    store_sales ss
JOIN 
    customer c ON ss.customer_sk = c.customer_sk
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim dd ON ss.sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    ca.city
ORDER BY 
    total_profit DESC
LIMIT 10;
