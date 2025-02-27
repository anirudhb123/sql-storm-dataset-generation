
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    STRING_AGG(DISTINCT CONCAT(wa.w_warehouse_name, ' (', wa.w_city, ', ', wa.w_state, ')'), '; ') AS warehouses,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    DATE_PART('year', d.d_date) AS year,
    EXTRACT(MONTH FROM d.d_date) AS month,
    STRING_AGG(DISTINCT wi.i_product_name) AS purchased_products
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
JOIN 
    item wi ON ws.ws_item_sk = wi.i_item_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, d.d_date
ORDER BY 
    total_spent DESC
LIMIT 10;
