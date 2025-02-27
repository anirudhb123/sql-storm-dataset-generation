
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ss_net_paid) AS total_sales,
    AVG(i_current_price) AS average_item_price,
    STRING_AGG(DISTINCT CONCAT(i_item_desc, ' (', i_item_id, ')'), '; ') AS items_sold
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item AS i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    ca_state = 'NY' 
    AND c.c_birth_year BETWEEN 1980 AND 1995
GROUP BY 
    ca_city
HAVING 
    SUM(ss_net_paid) > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
