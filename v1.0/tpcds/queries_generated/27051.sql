
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(ws.ws_sales_price) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) >= 1
ORDER BY 
    total_spent DESC
LIMIT 100;
