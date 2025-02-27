
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(ss.ext_sales_price) AS total_sales,
    AVG(ss.net_profit) AS average_profit,
    CASE 
        WHEN SUM(ss.net_sales) > 100000 THEN 'High Revenue' 
        WHEN SUM(ss.net_sales) BETWEEN 50000 AND 100000 THEN 'Moderate Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category,
    d.year AS sales_year
FROM 
    store_sales ss
JOIN 
    customer c ON ss.customer_sk = c.customer_sk
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ss.sold_date_sk = d.date_sk
WHERE 
    d.year BETWEEN 2020 AND 2023
GROUP BY 
    ca.city, d.year
ORDER BY 
    total_sales DESC, customer_city ASC
LIMIT 100;
