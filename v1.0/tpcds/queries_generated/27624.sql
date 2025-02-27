
SELECT 
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
    DATE_FORMAT(d.d_date, '%Y-%m') AS sales_month
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ws.ws_sales_price > 0
GROUP BY 
    ca.ca_city, ca.ca_state, DATE_FORMAT(d.d_date, '%Y-%m'), email_domain
HAVING 
    total_orders > 10 
ORDER BY 
    total_sales DESC, city;
