
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    cd.cd_gender AS customer_gender,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS accessed_web_pages,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_paid) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    ca.ca_city LIKE '%ville%' 
    AND cd.cd_gender = 'F' 
    AND cd.cd_purchase_estimate > 1000
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
ORDER BY 
    total_spent DESC
LIMIT 10;
