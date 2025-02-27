
SELECT 
    ca.ca_address_id AS address_id,
    ca.ca_street_name AS street_name,
    ca.ca_city AS city,
    ca.ca_state AS state,
    ca.ca_zip AS zip,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.c_email_address AS email,
    LENGTH(c.c_email_address) AS email_length,
    SUBSTRING_INDEX(c.c_email_address, '@', -1) AS email_domain,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    AVG(ws.ws_net_paid) AS average_order_value
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND cd.cd_gender = 'F'
GROUP BY 
    ca.ca_address_id,
    ca.ca_street_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
HAVING 
    total_orders > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
