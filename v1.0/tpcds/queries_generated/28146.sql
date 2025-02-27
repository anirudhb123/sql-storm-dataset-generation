
SELECT 
    SUBSTR(c.c_first_name, 1, 1) AS first_initial,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    CONCAT('Total Sales: $', TO_CHAR(SUM(ws.ws_ext_sales_price), 'FM999,999,999.00')) AS sales_summary,
    TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS full_address
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA' 
    AND cd.cd_gender = 'F'
    AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
