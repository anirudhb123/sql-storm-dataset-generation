
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales,
    SUM(s.ss_net_paid) AS total_sales_amount,
    AVG(s.ss_sales_price) AS avg_sales_price,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    promotion p ON s.ss_promo_sk = p.p_promo_sk
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    d.d_year = 2023
    AND ca.ca_state IN ('CA', 'NY', 'TX')
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
ORDER BY 
    total_sales_amount DESC
LIMIT 50;
