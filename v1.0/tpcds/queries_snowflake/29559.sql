
SELECT 
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales_value,
    AVG(ws.ws_sales_price) AS average_order_value,
    LISTAGG(DISTINCT cd.cd_gender || ' - ' || cd.cd_marital_status, ', ') AS demographics_info,
    CONCAT('City: ', ca.ca_city, ', State: ', ca.ca_state) AS location_info
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_sales_value DESC
LIMIT 10;
