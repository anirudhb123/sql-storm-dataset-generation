
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    d.d_date AS purchase_date,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND ca.ca_state IN ('CA', 'NY', 'TX')
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_date
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
