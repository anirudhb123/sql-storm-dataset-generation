
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    a.ca_city,
    a.ca_state,
    d.d_date AS purchase_date,
    i.i_item_desc,
    SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity,
    SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_sales,
    COUNT(DISTINCT CASE 
        WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number 
        END) AS order_count,
    LISTAGG(DISTINCT p.p_promo_name, '; ') WITHIN GROUP (ORDER BY p.p_promo_name) AS applied_promotions
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    c.c_birth_country = 'USA'
AND 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, d.d_date, i.i_item_desc
ORDER BY 
    total_sales DESC
LIMIT 100;
