
SELECT 
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    a.ca_city AS city,
    a.ca_state AS state,
    d.d_date AS purchase_date,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    LISTAGG(DISTINCT i.i_item_desc, ', ') WITHIN GROUP (ORDER BY i.i_item_desc) AS purchased_items,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 1000 THEN 'High Value'
        WHEN SUM(ws.ws_ext_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, d.d_date
ORDER BY 
    total_spent DESC
LIMIT 100;
