
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS average_order_value,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_items,
    DATE_TRUNC('month', d.d_date) AS month,
    d.d_year
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND (ca.ca_state = 'CA' OR ca.ca_state = 'NY')
GROUP BY 
    full_name, ca.ca_city, ca.ca_state, d.d_year, month
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_sales DESC;
