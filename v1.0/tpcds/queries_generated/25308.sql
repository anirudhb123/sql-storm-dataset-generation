
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    SUBSTRING(COALESCE(c.c_email_address, 'no_email@domain.com'), 1, POSITION('@' IN COALESCE(c.c_email_address, 'no_email@domain.com')) - 1) AS email_user,
    REPLACE(LOWER(ca.ca_street_name), ' ', '-') AS street_slug,
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS location,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(DATEDIFF(d.d_date, c.c_birth_year || '-' || c.c_birth_month || '-' || c.c_birth_day)) AS avg_age_days
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year IS NOT NULL AND
    d.d_year >= 2020
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_street_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 100;
