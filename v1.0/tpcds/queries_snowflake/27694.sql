
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    MAX(CASE WHEN ss.ss_sales_price > 50 THEN 'High' ELSE 'Low' END) AS sales_price_category,
    LISTAGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_item_id, ')'), ', ') WITHIN GROUP (ORDER BY i.i_item_id) AS items_purchased
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON i.i_item_sk = ss.ss_item_sk OR i.i_item_sk = ws.ws_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ss.ss_ticket_number) + COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_store_sales DESC, total_web_sales DESC;
