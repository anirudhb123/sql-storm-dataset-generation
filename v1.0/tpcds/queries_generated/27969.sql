
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    STRING_AGG(DISTINCT cd.cd_gender) AS unique_genders,
    STRING_AGG(DISTINCT cd.cd_marital_status) AS unique_marital_statuses
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sold_date_sk BETWEEN 2400 AND 2405 
GROUP BY 
    ca.ca_city 
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_quantity_sold DESC;
