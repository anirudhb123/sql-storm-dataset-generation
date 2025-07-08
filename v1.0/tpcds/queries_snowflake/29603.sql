
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(ss.ss_ticket_number) AS total_purchases,
    SUM(ss.ss_net_paid) AS total_spent,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date,
    LISTAGG(DISTINCT i.i_product_name, ', ') AS purchased_products
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
    AND ca.ca_city IS NOT NULL
    AND ca.ca_state IN ('CA', 'TX', 'NY')  
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
HAVING 
    COUNT(ss.ss_ticket_number) > 5
ORDER BY 
    total_spent DESC;
