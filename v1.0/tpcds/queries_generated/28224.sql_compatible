
SELECT 
    ca_state, 
    ca_city, 
    COUNT(DISTINCT c_customer_id) AS unique_customers, 
    COUNT(DISTINCT ws_web_page_id) AS unique_web_pages, 
    SUM(ws_net_paid) AS total_sales,
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name) ORDER BY c_last_name) AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca_state, ca_city
HAVING 
    SUM(ws_net_paid) > 10000
ORDER BY 
    total_sales DESC;
