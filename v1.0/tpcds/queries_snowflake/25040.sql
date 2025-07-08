
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    SUM(ss.ss_quantity) AS total_quantity_purchased,
    LISTAGG(DISTINCT CONCAT('Item: ', i.i_item_id, ', Desc: ', i.i_item_desc), '; ') WITHIN GROUP (ORDER BY i.i_item_id) AS purchased_items,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(d.d_date) AS last_purchase_date,
    AVG(ws.ws_sales_price) AS avg_purchase_price
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON ss.ss_item_sk = ws.ws_item_sk 
                AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_quantity) > 10
ORDER BY 
    total_quantity_purchased DESC;
