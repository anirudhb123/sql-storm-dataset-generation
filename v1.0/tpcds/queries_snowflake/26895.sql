
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    AVG(CASE WHEN cd.cd_gender = 'M' THEN cd.cd_dep_count ELSE NULL END) AS average_dependent_males,
    AVG(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_dep_count ELSE NULL END) AS average_dependent_females,
    SUM(CASE WHEN ws.ws_ext_sales_price > 1000 THEN 1 ELSE 0 END) AS high_value_sales,
    CONCAT(SUBSTRING(c.c_first_name, 1, 1), '.', c.c_last_name) AS customer_initials,
    LISTAGG(DISTINCT i.i_category, ', ') WITHIN GROUP (ORDER BY i.i_category) AS purchased_categories,
    DATE_TRUNC('month', d.d_date) AS month,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state, d.d_date, c.c_first_name, c.c_last_name
ORDER BY 
    ca.ca_state, ca.ca_city, month DESC;
