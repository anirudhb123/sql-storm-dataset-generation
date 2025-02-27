
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    ca.ca_city || ', ' || ca.ca_state AS customer_location,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    MAX(d.d_date) AS last_order_date,
    MIN(d.d_date) AS first_order_date,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) >= 500 THEN 'High Value'
        WHEN SUM(ws.ws_ext_sales_price) >= 200 AND SUM(ws.ws_ext_sales_price) < 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC;
