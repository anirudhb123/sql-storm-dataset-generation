
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain,
    cd.cd_marital_status,
    cd.cd_gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, cd.cd_marital_status, cd.cd_gender
ORDER BY 
    total_spent DESC
LIMIT 10;
