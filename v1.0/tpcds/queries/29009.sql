
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    AVG(ws.ws_net_paid) AS average_order_value,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS visited_web_pages,
    CASE
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    EXTRACT(YEAR FROM d.d_date) AS order_year
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, d.d_date
ORDER BY 
    total_spent DESC, total_orders DESC
LIMIT 100;
