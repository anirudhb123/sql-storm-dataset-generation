
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', wp.wp_type, wp.wp_url), '; ') AS web_page_details,
    SUBSTRING(c.c_email_address FROM 1 FOR 5) || '...' AS truncated_email,
    LEFT(ca.ca_street_name, 10) || '...' AS short_street_name
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
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_address_id, ca.ca_city, 
    ca.ca_state, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_spent DESC
LIMIT 100;
