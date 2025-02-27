
SELECT 
    ca.ca_state AS state,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    COUNT(ws.ws_order_number) AS total_web_sales,
    AVG(ws.ws_sales_price) AS average_sales_price,
    STRING_AGG(DISTINCT cd.cd_gender, ', ' ORDER BY cd.cd_gender) AS unique_genders,
    AVG(LENGTH(c.c_first_name)) AS average_first_name_length,
    AVG(LENGTH(c.c_last_name)) AS average_last_name_length
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
    ca.ca_state
ORDER BY 
    unique_customers DESC, total_web_sales DESC;
