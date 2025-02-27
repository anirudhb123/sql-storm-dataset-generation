
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_web_sales,
    SUM(CASE WHEN ws.ws_sales_price > 100 THEN 1 ELSE 0 END) AS high_value_orders,
    AVG(LENGTH(c.c_email_address)) AS avg_email_length,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS visited_web_pages
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    ca.ca_state = 'CA'
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_web_sales DESC
LIMIT 10;
