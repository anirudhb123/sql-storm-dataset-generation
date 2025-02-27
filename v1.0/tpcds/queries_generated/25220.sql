
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    d.d_date AS purchase_date,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY ca.ca_city) AS total_orders_in_city
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31' 
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state, d.d_date
ORDER BY 
    total_spent DESC
LIMIT 100;
