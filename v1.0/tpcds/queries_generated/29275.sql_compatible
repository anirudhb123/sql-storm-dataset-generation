
SELECT 
    ca.ca_city, 
    ca.ca_state, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name) ORDER BY c.c_last_name) AS customer_names,
    SUM(wr.wr_return_amt) AS total_returns
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
WHERE 
    ca.ca_country = 'USA' 
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_customers DESC, ca.ca_city ASC;
