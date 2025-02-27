
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    a.ca_state,
    ROUND(SUM(ws.ws_ext_sales_price), 2) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    STRING_AGG(DISTINCT i.i_brand || ' ' || i.i_product_name, ', ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    a.ca_state = 'NY'
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state
HAVING 
    SUM(ws.ws_ext_sales_price) > 5000
ORDER BY 
    total_sales DESC
LIMIT 10;
