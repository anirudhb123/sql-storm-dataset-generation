
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
    AVG(ss.ss_net_paid) AS average_spent,
    SUM(ss.ss_net_profit) AS total_profit,
    GROUP_CONCAT(DISTINCT CONCAT(i.i_item_desc, ' (', ss.ss_quantity, ')') ORDER BY ss.ss_ticket_number ASC SEPARATOR ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state, ca.ca_zip
HAVING 
    total_purchases > 5
ORDER BY 
    average_spent DESC;
