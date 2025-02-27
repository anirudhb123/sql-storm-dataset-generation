
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS aggregated_urls,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    MAX(d.d_date) AS last_order_date
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    web_page AS wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_state IN ('NY', 'CA') 
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_sales DESC
LIMIT 10;
