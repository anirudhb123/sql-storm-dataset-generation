
SELECT 
    ca_city,
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT cd_gender, ', ') AS genders_in_city
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_city IS NOT NULL 
    AND ca_state IN ('NY', 'CA', 'TX') 
    AND ws_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    ca_city, ca_state
ORDER BY 
    total_sales DESC;
