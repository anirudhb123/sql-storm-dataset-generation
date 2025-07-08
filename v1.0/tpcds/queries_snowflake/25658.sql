
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_tax) AS average_return_tax,
    LISTAGG(DISTINCT CONCAT(wp.wp_url, '(', wp.wp_type, ')'), ', ') WITHIN GROUP (ORDER BY wp.wp_url) AS accessed_web_pages
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY') 
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT wr.wr_order_number) > 0
ORDER BY 
    total_return_amount DESC
LIMIT 10;
