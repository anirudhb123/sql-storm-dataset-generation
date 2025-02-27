
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    MAX(ws.ws_sales_price) AS highest_item_price,
    MIN(ws.ws_sales_price) AS lowest_item_price,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS applied_promotions,
    STRING_AGG(DISTINCT item.i_item_desc, '; ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    item ON ws.ws_item_sk = item.i_item_sk
WHERE 
    ca.ca_state = 'NY' 
    AND c.c_birth_year BETWEEN 1980 AND 1990 
    AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2022)
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_sales DESC;
