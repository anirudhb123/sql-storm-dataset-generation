
SELECT 
    c.c_customer_id,
    CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
    a.ca_city,
    a.ca_state,
    d.d_date,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(ss.ss_ticket_number) AS total_purchases,
    AVG(ss.ss_net_paid) AS avg_purchase_value,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promo_names
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_salutation, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, d.d_date
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_spent DESC;
