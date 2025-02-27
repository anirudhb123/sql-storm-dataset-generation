
SELECT 
    ca.state AS customer_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    AVG(cd.purchase_estimate) AS average_purchase_estimate,
    COUNT(DISTINCT ss.ticket_number) AS total_sales,
    SUM(ss.net_profit) AS total_net_profit
FROM 
    customer_address ca
JOIN 
    customer c ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_city LIKE '%New%' 
    AND cd.cd_marital_status = 'M' 
    AND YEAR(c.c_birth_year) BETWEEN 1970 AND 1990
GROUP BY 
    ca.state
HAVING 
    total_sales > 10
ORDER BY 
    total_net_profit DESC;
