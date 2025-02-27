
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(i.i_current_price) AS average_item_price,
    STRING_AGG(DISTINCT cd.cd_marital_status, ', ') AS marital_statuses,
    CONCAT('Average Price: ', ROUND(AVG(i.i_current_price), 2)) AS formatted_average_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
    AND i.i_current_price IS NOT NULL
GROUP BY 
    ca.ca_city
ORDER BY 
    unique_customers DESC;
