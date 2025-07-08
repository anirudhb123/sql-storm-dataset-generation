
SELECT 
    TRIM(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 1 AND 1000
GROUP BY 
    c.c_customer_sk, 
    full_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC;
