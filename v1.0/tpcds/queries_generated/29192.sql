
SELECT 
    ca.ca_address_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name, 
    c.c_birth_month, 
    c.c_birth_year, 
    SUBSTRING_INDEX(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', -1) AS last_name_extracted,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_net_paid) AS total_spent,
    MIN(d.d_date) AS first_order_date,
    MAX(d.d_date) AS last_order_date,
    GROUP_CONCAT(DISTINCT i.i_product_name ORDER BY i.i_product_name ASC SEPARATOR ', ') AS products_ordered,
    LENGTH(c.c_email_address) AS email_length,
    INSTR(c.c_email_address, '@') AS at_symbol_position
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    (c.c_birth_month = 12 AND c.c_birth_year BETWEEN 1980 AND 1990)
    OR (c.c_preferred_cust_flag = 'Y' AND LENGTH(c.c_first_name) >= 5)
GROUP BY 
    ca.ca_address_id, 
    c.c_first_name, 
    c.c_last_name, 
    c.c_birth_month, 
    c.c_birth_year
HAVING 
    total_spent > 100
ORDER BY 
    total_orders DESC, 
    total_spent DESC LIMIT 50;
