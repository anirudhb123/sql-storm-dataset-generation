
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
    SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE NULL END) AS avg_sale_price,
    MAX(ca.ca_zip) AS max_zip_code,
    MIN(ca.ca_zip) AS min_zip_code,
    GROUP_CONCAT(DISTINCT ca.ca_street_name ORDER BY ca.ca_street_name SEPARATOR ', ') AS street_names,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(COALESCE(ws.ws_quantity, 0)) DESC) AS state_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state, c.c_first_name, c.c_last_name
HAVING 
    total_spent > 1000
ORDER BY 
    total_quantity DESC, total_spent DESC;
