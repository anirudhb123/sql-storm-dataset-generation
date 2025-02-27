
SELECT 
    ca.city AS customer_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ws.net_profit) AS total_net_profit,
    AVG(d.d_year) AS average_purchase_year,
    LISTAGG(DISTINCT i.i_product_name, ', ') WITHIN GROUP (ORDER BY i.i_product_name) AS featured_products
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year BETWEEN 2019 AND 2023
GROUP BY 
    ca.city
HAVING 
    SUM(ws.net_profit) > 100000
ORDER BY 
    total_net_profit DESC
FETCH NEXT 10 ROWS ONLY;
