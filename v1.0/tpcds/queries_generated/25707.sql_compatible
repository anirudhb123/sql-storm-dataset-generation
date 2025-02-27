
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ss.ss_sales_price) AS total_sales,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date,
    COUNT(ss.ss_ticket_number) AS purchase_count,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_items,
    STRING_AGG(DISTINCT sm.sm_type, ', ') AS ship_modes
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_sales_price) > 500
ORDER BY 
    total_sales DESC;
