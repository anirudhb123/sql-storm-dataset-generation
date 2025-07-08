
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    LISTAGG(DISTINCT i.i_product_name, ', ') AS purchased_products,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_city LIKE '%York%'
    AND c.c_birth_year BETWEEN 1970 AND 1980
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 3
ORDER BY 
    total_sales DESC
LIMIT 10;
