
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_revenue,
    AVG(CASE 
            WHEN c.c_birth_month BETWEEN 1 AND 6 THEN 1 
            ELSE 2 
        END) AS birth_month_half,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 100;
