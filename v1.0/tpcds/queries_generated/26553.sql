
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS average_order_value,
    MAX(ws.ws_sales_price) AS max_order_value,
    MIN(ws.ws_sales_price) AS min_order_value,
    STRING_AGG(DISTINCT cp.cp_department, ', ') AS departments_purchased_from,
    COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages_visited
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_page AS cp ON ws.ws_web_page_sk = cp.cp_catalog_page_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND cd.cd_marital_status = 'M'
    AND ws.ws_sold_date_sk BETWEEN 2458920 AND 2458950 -- Date range (e.g., within a specific month)
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state, cd.cd_gender
HAVING 
    COUNT(ws.ws_order_number) > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
