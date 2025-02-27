
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    LEFT(ca.ca_zip, 5) AS zip_code_prefix,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    STRING_AGG(DISTINCT CASE 
        WHEN ws.ws_sales_price > 100 THEN 'High Value'
        WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value' 
    END, ', ') AS spending_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND DATE_PART('year', CURRENT_DATE) - c.c_birth_year BETWEEN 25 AND 45
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_zip
ORDER BY 
    total_spent DESC
LIMIT 10;
