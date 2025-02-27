
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COUNT(sr.ticket_number) AS total_returns,
    SUM(sr.return_amt) AS total_return_amount
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    ca.city
ORDER BY 
    total_return_amount DESC
LIMIT 10;
