
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(DATEDIFF(d.d_date, c.c_birth_year)) AS average_age,
    SUBSTRING_INDEX(sm.sm_type, ' ', 1) AS primary_ship_mode,
    GROUP_CONCAT(DISTINCT r.r_reason_desc ORDER BY r.r_reason_desc SEPARATOR ', ') AS return_reasons
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_state = 'CA' 
    AND d.d_year = 2023 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state, sm.sm_type
HAVING 
    total_spent > 500
ORDER BY 
    total_orders DESC, total_spent DESC;
