
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    MIN(d.d_date) AS first_order_date,
    MAX(d.d_date) AS last_order_date,
    LISTAGG(DISTINCT wp.wp_url, ', ') AS visited_websites,
    LISTAGG(DISTINCT p.p_promo_name, ', ') AS promotions_used
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state = 'CA'
    AND d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
