
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    LISTAGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    DATE_TRUNC('month', d.d_date) AS month_of_order,
    EXTRACT(YEAR FROM d.d_date) AS order_year
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND d.d_date >= '2023-01-01' AND d.d_date < '2024-01-01'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, DATE_TRUNC('month', d.d_date), EXTRACT(YEAR FROM d.d_date)
ORDER BY 
    total_spent DESC
LIMIT 100;
