
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    LEFT(c.c_email_address, CHAR_LENGTH(c.c_email_address) - CHAR_LENGTH(SUBSTRING_INDEX(c.c_email_address, '@', -1)) - 1) AS obfuscated_email
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
    AND cd.cd_marital_status = 'M'
    AND ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, cd.cd_gender
HAVING 
    total_orders > 5
ORDER BY 
    total_spent DESC
LIMIT 100;
