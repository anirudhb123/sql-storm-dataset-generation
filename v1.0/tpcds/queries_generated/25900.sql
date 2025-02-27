
SELECT 
    c.c_first_name,
    c.c_last_name,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    REPLACE(REPLACE(REPLACE(c.c_email_address, '@', '_at_'), '.', '_dot_'), '-', '_dash_') AS sanitized_email,
    d.d_date AS purchase_date,
    COUNT(ss.ss_ticket_number) AS total_purchases,
    SUM(ss.ss_net_paid) AS total_spent,
    AVG(i.i_current_price) AS avg_item_price,
    STRING_AGG(DISTINCT w.w_warehouse_name, ', ') AS warehouse_names
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE 
    c.c_birth_month BETWEEN 1 AND 6 AND
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_date
ORDER BY 
    total_spent DESC
LIMIT 100;
