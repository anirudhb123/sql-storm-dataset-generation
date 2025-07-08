
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS avg_order_value,
    LISTAGG(DISTINCT i.i_item_desc, ', ') AS items_purchased,
    d.d_day_name,
    d.d_date
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
    c.c_birth_month = 12 
    AND d.d_year = 2022
GROUP BY 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    d.d_day_name,
    d.d_date
ORDER BY 
    total_sales DESC
LIMIT 10;
