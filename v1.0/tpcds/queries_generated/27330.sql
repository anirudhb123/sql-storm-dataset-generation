
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city, 
    ca.ca_state,
    d.d_date AS purchase_date,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year = 2023 
    AND ca.ca_state IN ('NY', 'CA', 'TX') 
GROUP BY 
    customer_name, ca.ca_city, ca.ca_state, purchase_date
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC, customer_name;
